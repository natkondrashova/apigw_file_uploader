module "lambda_get_s3_object" {
  source        = "./modules/lambda"
  function_name = "get_s3_object"
  project       = var.project
  env           = var.env
  tags          = local.tags

  filepath = "${path.module}/files/lambda"
  filename = "get_s3_object.py"

  iam_policy_arn = {
    s3       = aws_iam_policy.allow_read_s3.arn,
    dynamodb = aws_iam_policy.dynamodb.arn
  }

  env_vars = {
    "S3_BUCKET"      = var.s3_bucket_name,
    "DYNAMODB_TABLE" = aws_dynamodb_table.this.name
    "LOG_LEVEL"      = "DEBUG"
  }

  depends_on = [
    aws_iam_policy.allow_read_s3,
    aws_iam_policy.dynamodb
  ]
}

resource "aws_lambda_permission" "lambda_get_object" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_get_s3_object.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

data "aws_iam_policy_document" "dynamodb" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:UpdateItem"
    ]
    resources = [aws_dynamodb_table.this.arn]
  }
}

resource "aws_iam_policy" "dynamodb" {
  name   = "${var.project}_${var.env}_dynamodb"
  policy = data.aws_iam_policy_document.dynamodb.json
}
