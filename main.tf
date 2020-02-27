provider "aws" {
  region = "us-west-1"
}

resource "aws_vpc" "my_fugue_cicd_vpc" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "my-fugue-cicd-vpc"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.my_fugue_cicd_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
