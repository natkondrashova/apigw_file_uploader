resource "aws_kinesis_firehose_delivery_stream" "kinesis_stream" {
  name        = "${var.kinesis_stream_name}-${var.project}-${var.env}"
  destination = "s3"

  s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.kinesis_bucket.arn
  }

  tags = local.tags
}

data "aws_iam_policy_document" "firehose_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      identifiers = ["firehose.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "firehose_role" {
  name               = "${var.project}_${var.env}_firehose"
  assume_role_policy = data.aws_iam_policy_document.firehose_role.json
}

data "aws_iam_policy_document" "allow_write_s3" {
  statement {
    actions = ["s3:*"]
    effect  = "Allow"
    resources = [
      aws_s3_bucket.kinesis_bucket.arn,
      "${aws_s3_bucket.kinesis_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "allow_write_s3" {
  name   = "${var.project}_${var.env}_allow_write_s3"
  path   = "/"
  policy = data.aws_iam_policy_document.allow_write_s3.json
}

resource "aws_iam_role_policy_attachment" "from_kinesis_to_s3" {
  policy_arn = aws_iam_policy.allow_write_s3.arn
  role       = aws_iam_role.firehose_role.name
}
