module "lambda_authorizer" {
  source        = "./modules/lambda"
  function_name = "authorizer"
  project       = var.project
  env           = var.env
  tags          = local.tags

  filepath = "${path.module}/files/lambda"
  filename = "authorizer.py"

  env_vars = {
    "TOKEN" = var.authorization_token
  }
}

resource "aws_lambda_permission" "lambda_authorizer" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_authorizer.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}
