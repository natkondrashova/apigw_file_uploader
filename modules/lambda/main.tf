locals {
  handler = var.handler == "" ? "${var.function_name}.lambda_handler" : var.handler
}

data "archive_file" "this" {
  type                    = "zip"
  source_content          = file("${var.filepath}/${var.filename}")
  source_content_filename = var.filename

  output_path = "${var.filepath}/${replace(var.filename, ".py", ".zip")}"
}

resource "aws_lambda_function" "this" {
  function_name    = "${var.function_name}-${var.project}-${var.env}"
  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256

  handler = local.handler
  runtime = var.runtime
  role    = aws_iam_role.this.arn

  # TODO: handling the case when no variables are passed
  environment {
    variables = var.env_vars
  }

  depends_on = [
    aws_iam_role.this,
    aws_iam_role_policy_attachment.this
  ]

  tags = var.tags
}
