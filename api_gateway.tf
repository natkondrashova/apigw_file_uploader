data "aws_region" "this" {}

resource "aws_api_gateway_rest_api" "this" {
  name        = "api-${var.project}-${var.env}"
  description = "API for file uploader"

  tags = local.tags
}

resource "aws_api_gateway_authorizer" "this" {
  name           = "api-${var.project}-${var.env}-authorizer"
  rest_api_id    = aws_api_gateway_rest_api.this.id
  authorizer_uri = module.lambda_authorizer.lambda_invoke_arn
}

resource "aws_api_gateway_resource" "objects" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "objects"
}

resource "aws_api_gateway_method" "get_objects" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.objects.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.this.id
}

resource "aws_api_gateway_method_settings" "get_objects" {
  count = var.allow_api_gw_logging ? 1 : 0

  method_path = "${aws_api_gateway_resource.objects.path_part}/${aws_api_gateway_method.get_objects.http_method}"
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = var.env
  settings {
    logging_level = "INFO"
  }

  depends_on = [
    aws_api_gateway_method.get_objects,
    aws_api_gateway_deployment.apigw,
//    aws_api_gateway_resource.id
  ]
}

resource "aws_api_gateway_method" "put_objects" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.objects.id
  http_method   = "PUT"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.this.id
}

resource "aws_api_gateway_method_settings" "put_objects" {
  count = var.allow_api_gw_logging ? 1 : 0

  method_path = "${aws_api_gateway_resource.objects.path_part}/${aws_api_gateway_method.put_objects.http_method}"
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = var.env
  settings {
    logging_level = "INFO"
  }

  depends_on = [
    aws_api_gateway_method.put_objects,
    aws_api_gateway_deployment.apigw
  ]
}

resource "aws_api_gateway_integration" "lambda_get_objects" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_method.get_objects.resource_id
  http_method = aws_api_gateway_method.get_objects.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_list_s3_objects.lambda_invoke_arn
}

resource "aws_api_gateway_integration" "kinesis_put_objects" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_method.put_objects.resource_id
  http_method = aws_api_gateway_method.put_objects.http_method

  integration_http_method = "POST"
  type                    = "AWS"
  credentials             = aws_iam_role.apigateway.arn

  uri = "arn:aws:apigateway:${data.aws_region.this.name}:firehose:action/PutRecord" // TODO: parametrize

  request_templates = {
    "application/json" = <<EOF
{
   "DeliveryStreamName": "${aws_kinesis_firehose_delivery_stream.kinesis_stream.name}",
   "Record": {
      "Data": "$util.base64Encode($input.json('$.Data'))"
   }
}
EOF
  }
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.objects.id
  http_method = aws_api_gateway_method.put_objects.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "kinesis_response" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.objects.id
  http_method = aws_api_gateway_method.put_objects.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  depends_on = [
    aws_api_gateway_integration.kinesis_put_objects
  ]
}

resource "aws_api_gateway_resource" "id" {
  parent_id   = aws_api_gateway_resource.objects.id
  path_part   = "{objectID}"
  rest_api_id = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_method" "describe_object" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.id.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.this.id

  request_parameters = {
    "method.request.path.objectID" = true
  }
}

resource "aws_api_gateway_integration" "lambda_describe_object" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_method.describe_object.resource_id
  http_method = aws_api_gateway_method.describe_object.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_get_s3_object.lambda_invoke_arn
}

resource "aws_api_gateway_method" "delete_object" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.id.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.this.id

  request_parameters = {
    "method.request.path.objectID" = true
  }
}

resource "aws_api_gateway_integration" "lambda_delete_object" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_method.delete_object.resource_id
  http_method = aws_api_gateway_method.delete_object.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_delete_object.lambda_invoke_arn
}

resource "aws_api_gateway_deployment" "apigw" {
  depends_on = [
    aws_api_gateway_integration.lambda_get_objects,
    aws_api_gateway_integration.lambda_describe_object,
    aws_api_gateway_integration.kinesis_put_objects,
    aws_api_gateway_integration.lambda_delete_object
  ]

  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = var.env
}


data "aws_iam_policy_document" "apigw" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      identifiers = ["apigateway.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "apigateway" {
  name               = "${var.project}_${var.env}_apigw"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.apigw.json
}

data "aws_iam_policy_document" "kinesis" {
  statement {
    actions = [
      "firehose:*"
    ]
    effect = "Allow"
    resources = [
      aws_kinesis_firehose_delivery_stream.kinesis_stream.arn,
    ]
  }
}

resource "aws_iam_policy" "kinesis" {
  name   = "${var.project}_${var.env}_kinesis"
  path   = "/"
  policy = data.aws_iam_policy_document.kinesis.json
}

resource "aws_iam_role_policy_attachment" "kinesis" {
  policy_arn = aws_iam_policy.kinesis.arn
  role       = aws_iam_role.apigateway.name
}

resource "aws_iam_role" "apigateway_logs" {
  count = var.allow_api_gw_logging ? 1 : 0

  name               = "${var.project}_${var.env}_apigw_logs"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.apigw.json
}

resource "aws_iam_role_policy_attachment" "logs" {
  count = var.allow_api_gw_logging ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
  role       = aws_iam_role.apigateway_logs[0].name
}

resource "aws_api_gateway_account" "this" {
  count = var.allow_api_gw_logging ? 1 : 0

  cloudwatch_role_arn = aws_iam_role.apigateway_logs[0].arn
}
