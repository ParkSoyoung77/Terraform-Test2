import json, os, boto3
import urllib.request # 내부 라이브러리, HTTP요청 처리 모듈

def lambda_handler(event, context):
    # 슬랙의 Webhook URL
    SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL", "")
    
    # 슬랙에 전송할 메세지 설정
    message = "슬랙 메세지 전송 테스트"

    # 웹훅이 설정되지 않은 경우 작업 종료
    if not SLACK_WEBHOOK_URL:
        return
    payload = {
        "text": message
    }

    req = urllib.request.Request(
        SLACK_WEBHOOK_URL,
        data = json.dumps(payload).encode("utf-8"),  # 전체 데이터의 헤더값 설정
        headers = {'Content-Type': 'application/json'}
    )

    try:
        # 만들어진 데이터(req)를 슬랙에 전송
        urllib.request.urlopen(req)

        return {
            'statusCode': 200,
            'body': json.dumps('Test Message Send Successfully!!!')
        }
    except Exception as e:
        print(f"Slack 알림 전송 실패: {e}")
        return e