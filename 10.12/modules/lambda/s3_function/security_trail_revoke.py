import json, os, boto3
import urllib.request # 내부 라이브러리, HTTP요청 처리 모듈

def lambda_handler(event, context):
    # 슬랙의 Webhook URL
    SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL", "")

    req = urllib.request.Request(
        SLACK_WEBHOOK_URL,
        data = json.dumps({ # 저장할 데이터
            "text": "메세지 테스트"
        }).encode("utf-8"),  # 전체 데이터의 헤더값 설정
        headers = {'Content-Type': 'application/json'}
    )

    # 만들어진 데이터(req)를 슬랙에 전송
    urllib.request.urlopen(req)

    return {
        'statusCode': 200,
        'body': json.dumps('Test Message Send Successfully!!!')
    }