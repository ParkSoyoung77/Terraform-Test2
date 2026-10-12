import json, os, boto3
import urllib.request # 내부 라이브러리, HTTP요청 처리 모듈

def send_slack_message(message):
    # 슬랙의 Webhook URL
    SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL", "")

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

def lambda_handler(event, context):
    detail = event("detail", {})   # 이벤트 페이로드에서 정보 반환
    # 이벤트를 발생(실행)시킨 사용자 또는역할의 ARN 반환
    user_identity = detail.get("userIdentity", {})
    
    # 중요:
    if "security_trail_revoke-role" in user_identity:
        return

    # 슬랙에 전송할 메세지 설정
    message = (
        f"● *[보안 위험 자동 차단 완료]*\n"
        f"● *보안 그룹 ID*: '{group_id}'\n"
        f"● *위반 작업자*: '{user_identity}'\n"
        f"● *위반 내용*: SSH(22) 포트 '0.0.0.0/0' 퍼블릭 오픈\n"
        f"● *보안 그룹 ID*: 해당 Inbound Rule 자동 삭제 처리됨 "
    )
    
    # 메세지 전송 함수 호출
    send_slack_message(message)