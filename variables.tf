locals {
  tags = {
    "env"     = var.env
    "project" = var.project
  }
}
variable "project" { default = "jb-test" }
variable "env" { default = "dev" }
variable "s3_bucket_name" { default = "kinesis-bucket-2021-01-10" }
variable "dynamodb_name" { default = "kinesis_files_data" }
variable "dynamodb_read_cap" { default = 2 }
variable "dynamodb_write_cap" { default = 1 }
variable "kinesis_stream_name" { default = "kinesis-firehose" }
variable "allow_api_gw_logging" { default = false }
variable "authorization_token" {}
