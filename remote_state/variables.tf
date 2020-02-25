variable "aws_region" {
  default = "us-east-1"
}

variable "environment" {
  default = "security"
}

variable "s3_logs_bucket_name_prefix" {
  default = "fugue-ci-cd-example-logs"
}

variable "tfstate_bucket_name_prefix" {
  default = "fugue-ci-cd-example-tfstate"
}

variable "tfstate_lock_table_name" {
  default = "tfstate-lock"
}
