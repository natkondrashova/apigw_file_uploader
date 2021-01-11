module "lambda_list_s3_objects" {
  source        = "./modules/lambda"
  function_name = "list_s3_objects"
  project       = var.project
  env           = var.env
  tags          = local.tags

  filepath = "${path.module}/files/lambda"
  filename = "list_s3_objects.py"

  iam_policy_arn = {
    s3 = aws_iam_policy.allow_read_s3.arn,
  }

  env_vars = {
    "S3_BUCKET" = var.s3_bucket_name
    "LOG_LEVEL" = "DEBUG"
  }

  depends_on = [
    aws_iam_policy.allow_read_s3,
  ]
}

resource "aws_lambda_permission" "lambda_list_s3_objects" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_list_s3_objects.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

data "aws_iam_policy_document" "allow_read_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:Get*",
      "s3:Describe*"
    ]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*",
    ]
  }
}

resource "aws_iam_policy" "allow_read_s3" {
  name   = "${var.project}_${var.env}_lambda_allow_read_s3"
  path   = "/"
  policy = data.aws_iam_policy_document.allow_read_s3.json
}
