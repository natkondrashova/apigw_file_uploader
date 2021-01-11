resource "aws_s3_bucket" "kinesis_bucket" {
  bucket = var.s3_bucket_name
  acl    = "private"

  tags = merge(local.tags, {
    Name = "Kinesis Bucket"
  })
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.kinesis_bucket.id

  lambda_function {
    lambda_function_arn = module.lambda_put_item_dynamodb.lambda_arn
    events              = ["s3:ObjectCreated:*"]
  }

  lambda_function {
    lambda_function_arn = module.lambda_delete_item_dynamodb.lambda_arn
    events              = ["s3:ObjectRemoved:*"]
  }

  depends_on = [
    aws_lambda_permission.allow_delete_item_dynamodb,
    aws_lambda_permission.lambda_put_item_dynamodb
  ]
}
