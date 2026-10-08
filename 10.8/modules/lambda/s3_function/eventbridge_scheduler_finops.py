import json, boto3
import logging # CloudWatch Logs에 출력을 위한 로깅 모듈(라이브러리)

def lambda_handler(event, context):
    # TODO implement
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }