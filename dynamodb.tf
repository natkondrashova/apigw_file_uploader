resource "aws_dynamodb_table" "this" {
  name           = "${var.dynamodb_name}-${var.project}-${var.env}"
  billing_mode   = "PROVISIONED"
  read_capacity  = var.dynamodb_read_cap
  write_capacity = var.dynamodb_write_cap
  hash_key       = "ObjectID"

  attribute {
    name = "ObjectID"
    type = "S"
  }

  tags = merge(local.tags, {
    Name = var.dynamodb_name
  })
}
