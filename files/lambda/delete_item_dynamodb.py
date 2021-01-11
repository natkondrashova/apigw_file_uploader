import json
import os
import logging

import boto3

log = logging.getLogger("lambda")
log.setLevel(os.getenv("LOG_LEVEL", logging.INFO))


def lambda_handler(event, context):
    dynamodb_table_name = os.getenv("DYNAMODB_TABLE", "KinesisFiles")
    log.debug(f"dynamoDB table: {dynamodb_table_name}")
    objectID = get_key(event)
    if objectID:
        response = delete_item(objectID=objectID, dynamodb_table_name=dynamodb_table_name)
        return {
            'statusCode': 200,
            'body': json.dumps(response)
        }
    else:
        return {
            'statusCode': 400,
            'body': json.dumps({"message": "something went wrong"})
        }

def get_key(event):
    try:
        s3_bucket_name = event['Records'][0]['s3']['bucket']['name']
        s3_key = event['Records'][0]['s3']['object']['key']
        log.debug(f"s3 bucket: {s3_bucket_name}, s3_key: {s3_key}")
        return s3_key
    except:
        log.error("Can't retrieve s3 key")
        return False


def delete_item(objectID, dynamodb_table_name):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(dynamodb_table_name)
    response = table.delete_item(
       Key={ 'ObjectID': str(objectID) }
    )
    return response
