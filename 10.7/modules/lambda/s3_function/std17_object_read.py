"""
# ==========================================================================================
  s3_client = boto3.client("s3")
# ------------------------------------------------------------------------------------------
1. 객체 조회 및 다운로드
  <객체변수> = s3_client.get_object(Bucket="<target_bucket>", Key="<dir_path>/<file_name>")
  <변수> = <객체변수>["Body"].read().decode("utf-8")
2. 객체 목록 조회
  s3_client.list_objects_v2(Bucket="<target_bucket>", Prefix="<dir_path>/")
  - Prefix=디렉토리명/
3. 객체 삭제
  s3_client.delete_object(Bucket="<target_bucket>", Key="<dir_path>/<file_name>")
  -Key="디렉토리경로/파일명"
4. 다중 객체 삭제 (필수 아님)
  s3_client.delete_objects(
    Bucket="<target_bucket>",
    Delete={
      'Objects': [ # 아래 'Key'는 고정 
        {'Key': '<path1>/<file1>'},
        {'Key': '<path2>/<file2>'},
        {'Key': '<path3>/<file3>'}
      ],
      'Quiet': True # 기본값(False), True 설정할 경우 오류가 발생한 객체에 대한 응답 반환
    }
  )
5. 객체 복사 (필수)
  s3_client.copy_object(
    Bucket="<target_bucket>", # 복사본이 저장될 대상 버킷의 이름
    Key="<dir_path>/<file_name>", # 복사본이 저장될 객체의 경로 및 이름
    CopySource={
        "Bucket": "<source_bucket>",  # 원본 파일이 있는 버킷의 이름
        "Key": "<source_path>/<source_file>"  # 원본 파일의 경로 및 이름
    }
  )
6. 객체 업로드
  s3_client.put_object(
    Bucket="<target_bucket>",           # 업로드할 버킷
    Key="<dir_path>/<file_name>",       # 저장될 경로 및 이름
    Body=<파일 바이트>,                  # base64 로 받은 내용을 디코딩한 값
    ContentType="<MIME 타입>"           # 예: text/plain, image/png
  )
# ==========================================================================================
  호출 방법 (GET 쿼리스트링 또는 POST JSON 바디)
    ?action=list   &bucket_name=..&dir_name=..
    ?action=read   &bucket_name=..&dir_name=..&file_name=..
    ?action=delete &bucket_name=..&dir_name=..&file_name=..
    ?action=delete_many &bucket_name=..&dir_name=..&file_names=a.txt,b.txt
    ?action=copy   &bucket_name=..&dir_name=..&file_name=..
                   &target_bucket=..&target_dir=..&target_file=..   (비우면 원본과 같은 값)
    POST (body: JSON 문자열)
      {"action": "upload", "bucket_name": "..", "dir_name": "..", "file_name": "..",
       "content": "<base64>", "content_type": "text/plain", "overwrite": false}
      ※ 함수 URL 요청 한도(6MB) 때문에 파일 1개당 약 4MB 까지
# ==========================================================================================
"""
import json, boto3, base64, binascii, mimetypes
from botocore.exceptions import ClientError

s3_client = boto3.client("s3", region_name="eu-west-2")

ROOT_NAMES = ["Root", "ROOT", "root", "/", ""]
MAX_UPLOAD_BYTES = 4 * 1024 * 1024   # 업로드 파일 1개 최대 크기 (base64 로 커지면 함수 URL 한도 6MB 근접)


# 디렉토리명 + 파일명 → 객체 키
def make_key(dir_name, file_name):
    dir_name = (dir_name or "").strip().strip("/")
    file_name = (file_name or "").strip().lstrip("/")
    if dir_name in ROOT_NAMES:
        object_key = f"{file_name}"
    else:
        object_key = f"{dir_name}/{file_name}"
    return object_key


def lambda_handler(event, context):
    headers = {
        'Content-Type': 'application/json; charset=utf-8'
    }
    # CORS 는 함수 URL 설정에서 처리 (여기에 Access-Control-* 헤더를 또 넣으면 중복 → 브라우저 오류)

    def result(status, body):
        return {
            "statusCode": status,
            "headers": headers,
            "body": json.dumps(body, ensure_ascii=False, default=str)
        }

    # 브라우저 사전 요청(OPTIONS) 응답
    method = event.get("requestContext", {}).get("http", {}).get("method", "GET")
    if method == "OPTIONS":
        return result(200, {"message": "ok"})

    # 요청 값 읽기 (GET 쿼리스트링 + POST JSON 바디)
    params = dict(event.get("queryStringParameters") or {})
    if event.get("body"):
        raw_body = event["body"]
        if event.get("isBase64Encoded"):              # 함수 URL 이 바디를 base64 로 감싼 경우
            try:
                raw_body = base64.b64decode(raw_body).decode("utf-8")
            except (binascii.Error, UnicodeDecodeError):
                raw_body = ""
        try:
            body = json.loads(raw_body)
            if isinstance(body, dict):
                params.update(body)
        except (ValueError, TypeError):
            pass

    action = (params.get("action") or "read").strip()
    bucket_name = (params.get("bucket_name") or "").strip()
    dir_name = params.get("dir_name") or "/"
    file_name = (params.get("file_name") or "").strip()

    if not bucket_name:
        return result(400, {"error": "bucket_name 을 입력하세요."})

    try:
        # ------------------------------------------------------------------
        # 2. 객체 목록 조회
        # ------------------------------------------------------------------
        if action == "list":
            prefix = make_key(dir_name, "")          # "ex01/" 또는 "" (root)
            folders, files = [], []
            paginator = s3_client.get_paginator("list_objects_v2")
            for page in paginator.paginate(Bucket=bucket_name, Prefix=prefix, Delimiter="/"):
                folders += [p["Prefix"] for p in page.get("CommonPrefixes", [])]
                for obj in page.get("Contents", []):
                    if obj["Key"] == prefix:         # 폴더 자리표시 객체 제외
                        continue
                    files.append({
                        "key": obj["Key"],
                        "size": obj["Size"],
                        "last_modified": obj["LastModified"].isoformat()
                    })
            return result(200, {"bucket": bucket_name, "prefix": prefix,
                                "folders": folders, "files": files})

        # ------------------------------------------------------------------
        # 4. 다중 객체 삭제 (같은 디렉토리의 여러 파일)
        #    file_names = '["a.txt","b.txt"]' (JSON 배열) 또는 'a.txt,b.txt' (쉼표 구분)
        # ------------------------------------------------------------------
        if action == "delete_many":
            file_names = params.get("file_names") or ""
            if isinstance(file_names, str):
                text = file_names.strip()
                if text.startswith("["):
                    try:
                        file_names = json.loads(text)
                    except ValueError:
                        return result(400, {"error": "file_names 형식이 올바르지 않습니다."})
                else:
                    file_names = text.split(",")
            file_names = [str(f).strip() for f in file_names if str(f).strip()]

            if not file_names:
                return result(400, {"error": "file_names 를 입력하세요. (예: a.txt,b.txt)"})
            if len(file_names) > 1000:
                return result(400, {"error": "한 번에 최대 1000개까지 삭제할 수 있습니다."})

            object_keys = [make_key(dir_name, f) for f in file_names]
            response = s3_client.delete_objects(
                Bucket=bucket_name,
                Delete={
                    'Objects': [{'Key': k} for k in object_keys],  # 'Key' 는 고정
                    'Quiet': True                                  # 실패한 객체만 응답에 포함
                }
            )
            errors = [{"key": e.get("Key"), "code": e.get("Code"), "message": e.get("Message")}
                      for e in response.get("Errors", [])]
            return result(200 if not errors else 207, {
                "message": "다중 삭제 완료" if not errors else "일부 삭제 실패",
                "requested": len(object_keys),
                "deleted": len(object_keys) - len(errors),
                "keys": object_keys,
                "errors": errors
            })

        # 여기부터는 파일명이 필요
        if not file_name:
            return result(400, {"error": "file_name 을 입력하세요."})
        object_key = make_key(dir_name, file_name)

        # ------------------------------------------------------------------
        # 1. 객체 조회 및 다운로드 (읽기)
        # ------------------------------------------------------------------
        if action == "read":
            response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
            try:
                file_content = response["Body"].read().decode("utf-8")
            except UnicodeDecodeError:
                return result(415, {"error": "텍스트(UTF-8) 파일이 아니라서 내용을 표시할 수 없습니다."})

            return result(200, {
                "message": "읽기 완료",
                "bucket": bucket_name,
                "key": object_key,
                "size": response["ContentLength"],
                "content_type": response.get("ContentType", ""),
                "last_modified": response["LastModified"].isoformat(),
                "content": file_content
            })

        # ------------------------------------------------------------------
        # 3. 객체 삭제
        # ------------------------------------------------------------------
        if action == "delete":
            # delete_object 는 없는 파일도 성공으로 응답 → 먼저 존재 확인
            s3_client.head_object(Bucket=bucket_name, Key=object_key)
            s3_client.delete_object(Bucket=bucket_name, Key=object_key)
            return result(200, {"message": "삭제 완료", "bucket": bucket_name, "key": object_key})

        # ------------------------------------------------------------------
        # 5. 객체 복사
        # ------------------------------------------------------------------
        if action == "copy":
            target_bucket = (params.get("target_bucket") or bucket_name).strip()
            target_dir = params.get("target_dir") or dir_name
            target_file = (params.get("target_file") or file_name).strip()
            target_key = make_key(target_dir, target_file)

            if target_bucket == bucket_name and target_key == object_key:
                return result(400, {"error": "원본과 대상 경로가 같습니다."})

            s3_client.copy_object(
                Bucket=target_bucket,               # 복사본이 저장될 대상 버킷
                Key=target_key,                     # 복사본이 저장될 경로 및 이름
                CopySource={
                    "Bucket": bucket_name,          # 원본 버킷
                    "Key": object_key               # 원본 경로 및 이름
                }
            )
            return result(200, {
                "message": "복사 완료",
                "source": f"s3://{bucket_name}/{object_key}",
                "target": f"s3://{target_bucket}/{target_key}"
            })

        # ------------------------------------------------------------------
        # 6. 객체 업로드 (파일 1개씩 호출 → 여러 파일은 화면에서 반복 호출)
        # ------------------------------------------------------------------
        if action == "upload":
            if "/" in file_name or file_name in (".", ".."):
                return result(400, {"error": "파일명에 / 를 넣을 수 없습니다. 디렉토리는 dir_name 으로 지정하세요."})

            try:
                file_bytes = base64.b64decode(params.get("content") or "", validate=True)
            except (binascii.Error, ValueError):
                return result(400, {"error": "content 는 base64 문자열이어야 합니다."})
            if len(file_bytes) > MAX_UPLOAD_BYTES:
                return result(413, {"error": f"파일이 너무 큽니다 ({len(file_bytes)} bytes, 최대 {MAX_UPLOAD_BYTES})"})

            overwrite = str(params.get("overwrite", "false")).lower() in ("true", "1", "yes")
            if not overwrite:
                try:
                    s3_client.head_object(Bucket=bucket_name, Key=object_key)
                    return result(409, {"error": f"이미 같은 이름의 파일이 있습니다: s3://{bucket_name}/{object_key}"})
                except ClientError as e:
                    if e.response["Error"]["Code"] not in ("404", "NoSuchKey"):
                        raise

            content_type = (params.get("content_type") or "").strip() \
                or mimetypes.guess_type(file_name)[0] or "application/octet-stream"

            s3_client.put_object(
                Bucket=bucket_name,
                Key=object_key,
                Body=file_bytes,
                ContentType=content_type
            )
            return result(200, {
                "message": "업로드 완료",
                "bucket": bucket_name,
                "key": object_key,
                "size": len(file_bytes),
                "content_type": content_type
            })

        return result(400, {"error": f"지원하지 않는 action: {action}"})

    except ClientError as e:
        code = e.response["Error"]["Code"]
        status = 404 if code in ("404", "NoSuchKey", "NoSuchBucket") else \
                 403 if code in ("403", "AccessDenied") else 500
        message = "파일 또는 버킷이 없습니다." if status == 404 else e.response["Error"].get("Message", "")
        return result(status, {"error": f"{code}: {message}"})