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
# ==========================================================================================
"""
import json, os, boto3
from botocore.exceptions import ClientError

s3 = boto3.client('s3', region_name='eu-west-2')
def lambda_handler(event, context):
    headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'Access-Control-Allow-Origin': '*',                    # 모든 도메인/URL에서의 접근 허용
        'Access-Control-Allow-Headers': 'Content-Type',        # 허용할 요청 헤더
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'   # 허용할 HTTP 메서드
    }

    s3_client = boto3.client("s3")

    # 버킷 이름과 객체 키를 이용한 객체(파일) 로드(읽기)
    bucket_name = "std17-eu-west-2-bucket-test"
    dir_name = "ex01"
    file_name = "main.py"
    if dir_name in ["Root", "ROOT", "root", "/", ""]:
        object_key = f"{file_name}"
    else:
        object_key = f"{dir_name}/{file_name}"

    response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
    file_content = response["Body"].read().decode("utf-8")

    return {
        "statusCode": 200,
        "headers": headers,
        "body": file_content
    }
