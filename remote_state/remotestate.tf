provider "aws" {
  region  = var.aws_region
}

##########################
##### Logging Bucket #####
##########################
resource "aws_s3_bucket" "s3_logs_bucket" {
  bucket = "${var.s3_logs_bucket_name_prefix}-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  acl = "log-delivery-write"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"  # KMS encryption is not supported by access logging
      }
    }
  }

  lifecycle_rule {
    id = "transition_current_version"
    enabled = true

    transition {
      days = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 365
    }
  }

  lifecycle_rule {
    id = "transition_noncurrent_version"
    enabled = true

    noncurrent_version_transition {
      days = 30
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      days = 365
    }
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "s3_logs_bucket_blocker" {
  bucket = aws_s3_bucket.s3_logs_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
  
}

resource "aws_s3_bucket_policy" "s3_logs_bucket_policy" {
  bucket = aws_s3_bucket.s3_logs_bucket.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.s3_logs_bucket.id}/*",
            "Condition": {
                "StringNotEqualsIfExists": {
                    "s3:x-amz-server-side-encryption": "AES256"
                }
            }
        }
    ]
}
POLICY

}

###########################
##### Tf State Bucket #####
###########################
resource "aws_s3_bucket" "tfstate_bucket" {
  bucket        = "${var.tfstate_bucket_name_prefix}-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  acl           = "private"

  logging {
    target_bucket = aws_s3_bucket.s3_logs_bucket.id
    target_prefix = "${var.tfstate_bucket_name_prefix}-${data.aws_caller_identity.current.account_id}-${var.aws_region}/"
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.tfstate_key.arn
        sse_algorithm = "aws:kms"
      }
    }
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate_bucket_blocker" {
  bucket = aws_s3_bucket.tfstate_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
  
}

resource "aws_s3_bucket_policy" "tfstate_bucket_policy" {
  bucket = aws_s3_bucket.tfstate_bucket.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.tfstate_bucket.id}/*",
            "Condition": {
                "StringNotEqualsIfExists": {
                    "s3:x-amz-server-side-encryption": "SSE-KMS",
                    "s3:x-amz-server-side-encryption-aws-kms-key-id": "${aws_kms_key.tfstate_key.arn}"
                }
            }
        }
    ]
}
POLICY

}

###########################
##### Tf State Folder #####
###########################
resource "aws_s3_bucket_object" "tfstate_bucket_folder" {
  bucket = aws_s3_bucket.tfstate_bucket.id
  key = "tfstate-aws/"
  kms_key_id = aws_kms_key.tfstate_key.arn
}

############################
##### Tf State KMS Key #####
############################
resource "aws_kms_key" "tfstate_key" {
  is_enabled = true
  enable_key_rotation = true

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "key-default-1",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}
POLICY

  tags = {
    Environment = var.environment
  }
}

resource "aws_kms_alias" "tfstate_key_alias" {
  name = "alias/tfstate-key"
  target_key_id = aws_kms_key.tfstate_key.key_id
}

##############################
##### Tf State DDB Table #####
##############################
resource "aws_dynamodb_table" "tfstate-lock-table" {
  name = var.tfstate_lock_table_name
  read_capacity = 1
  write_capacity = 1
  hash_key = "LockID"

  attribute {
      name = "LockID"
      type = "S"
  }

  tags = {
    Environment = var.environment
  }
}
