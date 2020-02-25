terraform {
  backend "s3" {
    bucket = "fugue-ci-cd-example-tfstate-XXXXXXXXXXXX-us-east-1"
    key    = "tfstate-aws/main.tfstate"
    region = "us-east-1"

    dynamodb_table = "tfstate-lock"
  }
}
