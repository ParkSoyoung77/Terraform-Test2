import json, os, boto3
from botocore.exceptions import ClientError

s3 = boto3.resource('s3', region_name='eu-west-2')

# # Terraform이 관리하는 기본 버킷 — 삭제 금지 (Lambda 환경변수로 전달)
PROTECTED_BUCKET = os.environ.get('PROTECTED_BUCKET', '')
PREFIX = 'std17-'


def lambda_handler(event, context):
    cors_headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'Access-Control-Allow-Origin': '*',                    # 모든 도메인/URL에서의 접근 허용
        'Access-Control-Allow-Headers': 'Content-Type',        # 허용할 요청 헤더
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'   # 허용할 HTTP 메서드
    }

    def response(status, body):
        return {
            'statusCode': status,
            'headers': cors_headers,
            'body': json.dumps(body, ensure_ascii=False)
        }

    # queryStringParameters가 None이어도 빈 딕셔너리 {}로 처리하여 에러 방지
    # ?bucket_name=std17-eu-west-2-bucket-1234
    get_params = event.get('queryStringParameters') or {}
    bucket_name = (
        get_params.get('bucket_name')
        or os.environ.get('bucket_name')
        or "std17-eu-west-2-default-bucket"
    )

    # 삭제는 되돌릴 수 없으므로 AWS 호출 전에 먼저 검사
    if not bucket_name.startswith(PREFIX):
        return response(403, {'message': f"'{PREFIX}' 로 시작하는 버킷만 삭제할 수 있습니다.", 'bucket': bucket_name})
    if bucket_name == PROTECTED_BUCKET:
        return response(403, {'message': 'Terraform이 관리하는 버킷은 삭제할 수 없습니다.', 'bucket': bucket_name})

    bucket = s3.Bucket(bucket_name)

    try:
        has_objects = any(bucket.objects.all())  # 버킷에 객체가 있는지 확인
        if has_objects:
            # 버킷 비우기 (버전 관리가 꺼진 버킷 기준 — IAM 권한과 맞춤)
            bucket.objects.delete()

        # 버킷 삭제
        bucket.delete()
        print(f"Bucket '{bucket_name}' deleted.")
        # ⭕ 성공 응답 (200 OK)
        return response(200, {'message': 'Bucket deleted successfully!', 'bucket': bucket_name})

    except ClientError as e:
        error_code = e.response['Error']['Code']
        print(f"Error deleting bucket '{bucket_name}': {error_code}")

        # ❌ 실패 응답 — 원인별 상태 코드
        if error_code == 'NoSuchBucket':
            return response(404, {'message': '존재하지 않는 버킷입니다.', 'bucket': bucket_name})
        if error_code == 'AccessDenied':
            return response(403, {'message': '권한이 없습니다.', 'bucket': bucket_name})
        if error_code == 'BucketNotEmpty':
            return response(409, {'message': '버킷이 비어 있지 않습니다. 버전 관리가 켜진 버킷일 수 있습니다.', 'bucket': bucket_name})
        return response(500, {'error': str(e), 'bucket': bucket_name})