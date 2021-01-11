data "aws_iam_policy_document" "this" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "this" {
  name = "${var.project}_${var.env}_lambda_${var.function_name}"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.iam_policy_arn

  policy_arn = each.value
  role       = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "lambda_basic_permissions" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
