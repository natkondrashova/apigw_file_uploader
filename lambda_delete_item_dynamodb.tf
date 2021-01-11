module "lambda_delete_item_dynamodb" {
  source        = "./modules/lambda"
  function_name = "delete_item_dynamodb"
  project       = var.project
  env           = var.env
  tags          = local.tags

  filepath = "${path.module}/files/lambda"
  filename = "delete_item_dynamodb.py"

  iam_policy_arn = {
    dynamodb = aws_iam_policy.delete_item_dynamodb.arn
  }

  env_vars = {
    "S3_BUCKET"      = var.s3_bucket_name,
    "DYNAMODB_TABLE" = aws_dynamodb_table.this.name
    "LOG_LEVEL"      = "DEBUG"
  }

  depends_on = [
    aws_iam_policy.delete_item_dynamodb,
  ]
}

resource "aws_lambda_permission" "allow_delete_item_dynamodb" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_delete_item_dynamodb.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.kinesis_bucket.arn
}

data "aws_iam_policy_document" "delete_item_dynamodb" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:DeleteItem",
    ]
    resources = [aws_dynamodb_table.this.arn]
  }
}

resource "aws_iam_policy" "delete_item_dynamodb" {
  name   = "${var.project}_${var.env}_delete_item_dynamodb"
  policy = data.aws_iam_policy_document.delete_item_dynamodb.json
}
