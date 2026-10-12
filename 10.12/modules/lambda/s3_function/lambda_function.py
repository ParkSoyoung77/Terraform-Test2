import json, io, os, boto3, urllib.parse
from PIL import Image

ALLOWED_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.webp', '.gif'}

def lambda_handler(event, context):
    record = event['Records'][0]['s3']
    bucket_name = record['bucket']['name']

    raw_key = record['object']['key']
    object_key = urllib.parse.unquote_plus(raw_key)

    # ====================================================================
    # 대상 선정 확인
    # 썸네일 폴더 안에 이미지가 새로 생성될 경우 이후,
    # 더 이상 수행하지 않게 하여 무한 루프에 빠지지 않도록 하기위한 구성
    if object_key.startswith("thumbnails/"):
        return {"statusCode": 200, "body": "이미 썸네일 이미지인 상태입니다."}

    # 파일명 중 앞이름('uploads/sample')은 _ 에 할당하여 무시하고,
    # 확장자(.포함)만 file_extension에 저장
    _, file_extension = os.path.splitext(object_key)
    if file_extension.lower() not in ALLOWED_EXTENSIONS:
        return {"statusCode": 200, "body": "변환 할 수 없는 파일입니다."}

    # ====================================================================
    # 이미지 로드 및 크기 변경: 메모리 상태에서
    # 1. 이미지 객체 로드
    s3_client = boto3.client('s3')
    s3_resource = s3_client.get_object(Bucket=bucket_name, Key=object_key)
    image_bytes = s3_resource["Body"].read()

    # image = Image.open()
    # io.BytesIO(image_bytes): 메모리 상에서 이미지를 바이트 스트림으로 로드(디스크 절약)
    with Image.open(io.BytesIO(image_bytes)) as image:
        # JPEG 호환성 확보를 위한 RGB 모드로 RGBA 및 P를 수정
        if image.mode in ('RGBA', 'P'):
           image = image.convert("RGB")

        # 비율을 유지하며 이미지 크기 축소
        THUMBNAIL_SIZE = (200,200)
        image.thumbnail(THUMBNAIL_SIZE, Image.Resampling.LANCZOS)

        #생성된 썸네일 이미지를 메모리 버퍼에 바이트 형태로 지정
        buffer = io.BytesIO()
        img_format = "PNG" if file_extension.lower() == ".png" else "JPEG"
        image.save(buffer, format=img_format, quality=85)
        buffer.seek(0)  # 버퍼 포인트(커서)를 처음으로 이동
    # ====================================================================
    # 저장될 버킷 정보 및 업로드
    filename = os.path.basename(object_key)
    thumbnail_key = f"thumbnails/{filename}"

    content_type = f"image/{'png' if img_format == 'PNG' else 'jpeg'}"
    s3_client.put_object(
        Bucket=bucket_name,
        Key=thumbnail_key,
        Body=buffer,
        ContentType=content_type
    )

    # -------------------------
    print("성공")
    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Thumbnail created successfully', 'thumbnailKey': thumbnail_key})
    }
    # -------------------------