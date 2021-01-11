import json
import os
import logging

import boto3

log = logging.getLogger("lambda")
log.setLevel(os.getenv("LOG_LEVEL", logging.INFO))


def lambda_handler(event, context):
    s3_bucket_name = os.getenv("S3_BUCKET", "kinesis-bucket-2020-12-20")
    log.debug(f"s3 bucket: {s3_bucket_name}")
    s3 = boto3.resource('s3')
    s3_bucket = s3.Bucket(s3_bucket_name)
    list = []

    for key in s3_bucket.objects.all():
        log.debug(f"key: {key.key}")
        list.append(key.key)

    return {
        'statusCode': 200,
        'body': json.dumps(list)
    }
