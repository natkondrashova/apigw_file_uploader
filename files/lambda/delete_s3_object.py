import json
import os
import logging

import boto3
from botocore.exceptions import ClientError

log = logging.getLogger("lambda")
log.setLevel(os.getenv("LOG_LEVEL", logging.INFO))


def lambda_handler(event, context):
    s3_bucket_name = os.getenv("S3_BUCKET", "kinesis-bucket-2021-01-10")
    log.debug(f"s3 bucket: {s3_bucket_name}")
    dynamodb_table = os.getenv("DYNAMODB_TABLE", "kinesis_files_data-jb-test-dev")
    log.debug(f"dynamoDB table: {dynamodb_table}")
    objectID = event['pathParameters']['objectID'].replace("%2F", "/")
    log.debug(f"objectID = {objectID}")

    if delete_object_s3(s3_bucket_name, objectID):
        return {
            'statusCode': 200,
            'body': json.dumps({"message": "object has been successfully deleted"})
        }
    else:
        return {
            'statusCode': 400,
            'body': json.dumps({"message": "something went wrong"})
        }


def delete_object_s3(s3_bucket_name, objectID):
    client = boto3.client('s3')

    try:
        response = client.delete_object(
            Bucket=s3_bucket_name,
            Key=objectID
        )
        return response
    except ClientError as e:
        log.error(e.response['Error']['Message'])
    except:
        log.error("Something went wrong")

    return False
