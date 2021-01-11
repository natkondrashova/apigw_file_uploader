terraform {
  // TODO: state in S3
  required_version = "~> 0.14.2"
}

provider aws {
  region  = "us-east-2"
  profile = "temp"
}
