import datetime
import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")
BUCKET = os.environ["LOG_BUCKET"]
PREFIX = os.environ.get("LOG_PREFIX", "fastapi-logs")


def lambda_handler(event, context):
    now = datetime.datetime.now(datetime.timezone.utc)
    key = f"{PREFIX}/{now:%Y/%m/%d}/{now:%H%M%S}-{context.aws_request_id}.json"
    record = {"timestamp": now.isoformat(), **event}

    s3.put_object(
        Bucket=BUCKET,
        Key=key,
        Body=json.dumps(record, ensure_ascii=False).encode("utf-8"),
        ContentType="application/json",
    )
    logger.info(f"FastAPI 로그 저장 완료: s3://{BUCKET}/{key}")
    return {"bucket": BUCKET, "key": key}