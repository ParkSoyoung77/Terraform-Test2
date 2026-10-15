import json
import os
import boto3
from fastapi import FastAPI, Request

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
@app.post("/log")
def save_log(body: dict):
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