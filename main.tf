terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  backend "s3" {
    bucket = "sctp-ce12-tfstate-bucket" # Change this
    key    = "arista.tfstate"           # Change this - any name will do that need to be created.
    region = "ap-southeast-1"
  }
}

#resource "aws_s3_bucket" "s3_tf" {
#  bucket_prefix = "arista-ce12-7May-bucket" # Set your bucket name here
#}

resource "aws_s3_bucket" "s3_tf" {
  #checkov:skip=CKV_AWS_144:CRR not required for lab
  #checkov:skip=CKV2_AWS_62:Event notification not required
  #checkov:skip=CKV2_AWS_61:Lifecycle config not required
  #checkov:skip=CKV2_AWS_6:Public access block not required
  #checkov:skip=CKV_AWS_21:Versioning not required
  #checkov:skip=CKV_AWS_145:KMS encryption not required
  bucket_prefix = "arista-ce12-7May-bucket"
}

# Block public access
resource "aws_s3_bucket_public_access_block" "s3_tf" {
  bucket                  = aws_s3_bucket.s3_tf.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "s3_tf" {
  bucket = aws_s3_bucket.s3_tf.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption using KMS
resource "aws_kms_key" "s3_key" {
  #checkov:skip=CKV_AWS_7:Key rotation not required
  #checkov:skip=CKV2_AWS_64:Custom KMS policy not required
  description = "KMS key for S3 bucket encryption"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_tf" {
  #checkov:skip=CKV_AWS_300:Multipart upload cleanup not required
  bucket = aws_s3_bucket.s3_tf.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "s3_tf" {
  bucket = aws_s3_bucket.s3_tf.id

  rule {
    id     = "cleanup"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }
  }
}

# Logging bucket
resource "aws_s3_bucket" "log_bucket" {
  #checkov:skip=CKV_AWS_144:CRR not required for lab
  #checkov:skip=CKV2_AWS_62:Event notification not required
  #checkov:skip=CKV2_AWS_61:Lifecycle config not required
  #checkov:skip=CKV2_AWS_6:Public access block not required
  #checkov:skip=CKV_AWS_21:Versioning not required
  #checkov:skip=CKV_AWS_145:KMS encryption not required
  bucket_prefix = "arista-ce12-log-bucket"
}

resource "aws_s3_bucket_logging" "s3_tf" {
  bucket        = aws_s3_bucket.s3_tf.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

# Event notification
resource "aws_s3_bucket_notification" "s3_tf" {
  bucket = aws_s3_bucket.s3_tf.id
}