import json

import boto3
from fastapi import FastAPI, Request
from aws_xray_sdk.core import xray_recorder, patch_all

# X-Ray 설정 (boto3 클라이언트 생성 전에)
#   데몬 주소는 환경변수 AWS_XRAY_DAEMON_ADDRESS(xray-daemon:2000)를 자동 사용
xray_recorder.configure(
    service="std17-fastapi",
    sampling=False,                  # 모든 요청을 트레이스 (실습 확인용)
    context_missing="IGNORE_ERROR",  # 세그먼트 밖 호출이 있어도 앱이 죽지 않게
)
patch_all()                          # boto3 호출(Lambda invoke)을 서브세그먼트로 기록

with open("/app/config.json", encoding="utf-8") as f:
    CONFIG = json.load(f)

LOG_FILE = "/app/logs/fastapi.log"
lambda_client = boto3.client("lambda", region_name=CONFIG["region"])

app = FastAPI(title="std17 FastAPI")


def write_log(record: dict) -> None:
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")


def client_ip(request: Request) -> str:
    # ALB/프록시 뒤에서는 X-Forwarded-For 첫 번째 값이 실제 접속자 IP
    xff = request.headers.get("x-forwarded-for")
    if xff:
        return xff.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


# 접속 로그 미들웨어 (/health 제외)
@app.middleware("http")
async def log_requests(request: Request, call_next):
    response = await call_next(request)
    if request.url.path != "/health":
        write_log({
            "type": "access",
            "client": client_ip(request),
            "method": request.method,
            "path": request.url.path,
            "query": str(request.url.query),
            "status": response.status_code,
        })
    return response


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/")
def read_root():
    return {"message": "Welcome to std17 FastAPI with Access Logging!"}


@app.get("/items/{item_id}")
def read_item(item_id: int, q: str | None = None):
    return {"item_id": item_id, "q": q}


# 로그 저장: 로컬 파일 + Lambda(python3.14) 경유 S3
#   async def → X-Ray 세그먼트와 같은 스레드에서 실행돼 Lambda 호출이 트레이스에 포함됨
@app.post("/log")
async def save_log(body: dict):
    record = {"type": "app", "source": "fastapi", "data": body}
    write_log(record)
    try:
        resp = lambda_client.invoke(
            FunctionName=CONFIG["lambda_name"],
            InvocationType="RequestResponse",
            Payload=json.dumps(record, ensure_ascii=False).encode("utf-8"),
        )
        result = json.loads(resp["Payload"].read())
    except Exception as e:
        write_log({"type": "error", "where": "lambda.invoke", "error": str(e)})
        return {"saved_local": True, "saved_s3": False, "error": str(e)}
    return {"saved_local": True, "saved_s3": "FunctionError" not in resp, "lambda": result}


# X-Ray 미들웨어: 요청마다 세그먼트 생성 (마지막에 등록 → 가장 바깥에서 실행)
@app.middleware("http")
async def xray_middleware(request: Request, call_next):
    segment = xray_recorder.begin_segment("std17-fastapi")
    segment.put_http_meta("method", request.method)
    segment.put_http_meta("url", str(request.url))
    try:
        response = await call_next(request)
        segment.put_http_meta("status", response.status_code)
        return response
    except Exception as e:
        segment.add_exception(e, stack=None)
        raise
    finally:
        xray_recorder.end_segment()