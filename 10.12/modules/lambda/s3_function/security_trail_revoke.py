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
    detail = event.get("detail", {})   # 이벤트 페이로드에서 정보 반환
    # 이벤트를 발생(실행)시킨 사용자 또는역할의 ARN 반환
    user_identity = detail.get("userIdentity", {}).get('arn', '')

    ec2_client = boto3.client("ec2")

    # 중요: 중복 메시지 발송을 막기 위한 이중 이벤트 제어
    if "std17SecurityAutoRemediationRole" in user_identity:
        return

    req_params = detail.get("requestParameters", {})
    group_id = req_params.get("groupId")

    ip_perms = req_params.get("ipPermissions", {})  # 보안 그룹 인바운드 규칙
    perms_list = ip_perms if isinstance(ip_perms, list) else ip_perms.get("items", [])

    for perm in perms_list:
        if perm.get("fromPort") == 22 or perm.get("toPort") == 22:
            ip_ranges = perm.get("ipRanges", {})
            ranges_list = ip_ranges if isinstance(ip_ranges, list) else ip_ranges.get("items", [])

            # 0.0.0.0/0 이 포함된 경우에만 삭제
            if any(r.get("cidrIp") == "0.0.0.0/0" for r in ranges_list):
                # 인바운드 규칙 삭제
                ec2_client.revoke_security_group_ingress(
                    GroupId=group_id,
                    IpPermissions=[{
                        "IpProtocol": str(perm.get("ipProtocol", "tcp")),
                        "FromPort": perm.get("fromPort"),
                        "ToPort": perm.get("toPort"),
                        "IpRanges": [{"CidrIp": "0.0.0.0/0"}]
                    }]
                )

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