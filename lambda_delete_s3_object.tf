module "lambda_delete_object" {
  source        = "./modules/lambda"
  function_name = "delete_s3_object"
  project       = var.project
  env           = var.env
  tags          = local.tags

  filepath = "${path.module}/files/lambda"
  filename = "delete_s3_object.py"

  iam_policy_arn = {
    dynamodb = aws_iam_policy.delete_s3_object.arn
  }

  env_vars = {
    "S3_BUCKET"      = var.s3_bucket_name,
    "DYNAMODB_TABLE" = aws_dynamodb_table.this.name
    "LOG_LEVEL"      = "DEBUG"
  }

  depends_on = [
    aws_iam_policy.delete_s3_object
  ]
}

resource "aws_iam_policy" "delete_s3_object" {
  name   = "${var.project}_${var.env}_allow_delete_from_s3"
  policy = data.aws_iam_policy_document.delete_s3_object.json
}

data "aws_iam_policy_document" "delete_s3_object" {
  statement {
    effect = "Allow"
    actions = [
      "s3:Delete*",
    ]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }
}

resource "aws_lambda_permission" "lambda_delete_object" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_delete_object.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}