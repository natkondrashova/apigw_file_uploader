variable "function_name" {}
variable "filename" {}
variable "filepath" {}
variable "handler" { default = "" }
variable "runtime" { default = "python3.6" }
variable "iam_policy_arn" { default = {} }
variable "env_vars" {
  type    = map(string)
  default = {}
}

variable "tags" {}
variable "project" {}
variable "env" {}
