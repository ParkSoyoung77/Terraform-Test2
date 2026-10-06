import json
import os

import boto3
import pymysql

secrets = boto3.client("secretsmanager")


def get_password():
    value = secrets.get_secret_value(SecretId=os.environ["DB_SECRET_NAME"])["SecretString"]
    try:
        return json.loads(value)["password"]   # JSON 형식으로 저장된 경우
    except (json.JSONDecodeError, KeyError, TypeError):
        return value                           # 비밀번호만 저장된 경우


def lambda_handler(event, context):
    conn = None
    try:
        conn = pymysql.connect(
            host=os.environ["DB_HOST"],
            user="std17",
            password=get_password(),
            port=int(os.environ.get("DB_PORT", "3306")),
            charset="utf8mb4",
            cursorclass=pymysql.cursors.DictCursor,
            autocommit=False,
            connect_timeout=10,
        )
        with conn.cursor() as cursor:
            sql = """
            CREATE DATABASE testdb;
            """
            cursor.execute(sql)
            # result = cursor.fetchone()
            # print("Query Result:", result)

        # print("데이터베이스 연결 성공")
        # return {"statusCode": 200, "body": json.dumps({"connected": True})}
    except Exception as e:
        print("Error connecting to the database:", e)
        # return {"statusCode": 500, "body": json.dumps({"connected": False, "error": str(e)})}
    finally:
        if conn:
            conn.close()