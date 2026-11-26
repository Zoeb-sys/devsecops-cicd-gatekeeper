provider "aws" {
  region = "ap-south-1"
}

resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 default encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_s3_bucket" "hardened_bucket" {
  bucket = "devsecops-gatekeeper-demo-2026-unique"
}

resource "aws_s3_bucket" "access_logs_bucket" {
  bucket = "devsecops-gatekeeper-demo-2026-logs"
}

resource "aws_s3_bucket_public_access_block" "hardened_bucket_pab" {
  bucket = aws_s3_bucket.hardened_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "hardened_bucket_sse" {
  bucket = aws_s3_bucket.hardened_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
  }
}

resource "aws_s3_bucket_versioning" "hardened_bucket_versioning" {
  bucket = aws_s3_bucket.hardened_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "hardened_bucket_logging" {
  bucket = aws_s3_bucket.hardened_bucket.id

  target_bucket = aws_s3_bucket.access_logs_bucket.id
  target_prefix = "s3-access-logs/"
}

resource "aws_s3_bucket_lifecycle_configuration" "hardened_bucket_lifecycle" {
  bucket = aws_s3_bucket.hardened_bucket.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_vpc" "demo_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "demo_subnet" {
  vpc_id     = aws_vpc.demo_vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_security_group" "hardened_sg" {
  name        = "restricted-ssh-sg"
  description = "Restrict SSH to a trusted admin IP"
  vpc_id      = aws_vpc.demo_vpc.id

  ingress {
    description = "SSH restricted to trusted bastion/admin host"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["198.51.100.10/32"]
  }

  egress {
    description = "Allow HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_network_interface" "hardened_eni" {
  subnet_id       = aws_subnet.demo_subnet.id
  security_groups = [aws_security_group.hardened_sg.id]
}
