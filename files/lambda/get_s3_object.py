import json
import os
import logging

import boto3
from botocore.exceptions import ClientError

log = logging.getLogger("lambda")
log.setLevel(os.getenv("LOG_LEVEL", logging.INFO))


def lambda_handler(event, context):
    s3_bucket_name = os.getenv("S3_BUCKET", "kinesis-bucket-2020-12-20")
    log.debug(f"s3 bucket: {s3_bucket_name}")
    dynamodb_table = os.getenv("DYNAMODB_TABLE", "KinesisFiles")
    log.debug(f"dynamoDB table: {dynamodb_table}")
    objectID = event['pathParameters']['objectID'].replace("%2F", "/")
    log.debug(f"objectID = {objectID}")

    object_data = get_object_s3(s3_bucket_name, objectID)
    object_info = get_object_info(dynamodb_table, objectID)

    body = {"objectID": objectID}
    if object_data:
        body["s3_data"] = object_data
    else:
        body["error"] = "object not found"
    if object_info:
        body["dynamodb_info"] = object_info

    update_response = update_object(dynamodb_table, objectID)
    log.debug(f"update response: {update_response}")

    return {
        'statusCode': 200,
        'body': json.dumps(body)
    }


def get_object_s3(s3_bucket_name, objectID):
    client = boto3.client('s3')

    try:
        response = client.get_object(
            Bucket=s3_bucket_name,
            Key=objectID
        )

        resp = response["Body"].read().decode('utf8')
        log.debug(f"get_object_s3 resp = {resp}")

        return resp

    except ClientError as e:
        log.error(e.response['Error']['Message'])

    return False


def get_object_info(dynamodb_table, objectID):
    client = boto3.client('dynamodb')

    try:
        response = client.get_item(
            TableName=dynamodb_table,
            Key={
                'ObjectID': {
                    'S': str(objectID)
                }})

        resp = response["Item"]
        log.debug(f"get_object_info resp = {resp}")

        return resp

    except ClientError as e:
        log.error(e.response['Error']['Message'])

    return False

def update_object(dynamodb_table, objectID):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(dynamodb_table)

    try:
        response = table.update_item(
            Key={'ObjectID': objectID},
            UpdateExpression="set GetObjectEventCounter = GetObjectEventCounter + :val",
            ExpressionAttributeValues={':val': 1},
            ReturnValues="UPDATED_NEW"
        )
        return response

    except ClientError as e:
        log.error(e.response['Error']['Message'])

def get_object_info_(dynamodb_table, objectID):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(dynamodb_table)

    try:
        response = table.get_item(Key={'ObjectID': objectID})
        return response['Item']
    except ClientError as e:
        log.error(e.response['Error']['Message'])
