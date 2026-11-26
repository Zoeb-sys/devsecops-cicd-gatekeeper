provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "hardened_bucket" {
  bucket = "devsecops-gatekeeper-demo-2026-unique"
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
      sse_algorithm = "aws:kms"
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

  target_bucket = aws_s3_bucket.hardened_bucket.id
  target_prefix = "access-logs/"
}

resource "aws_s3_bucket_lifecycle_configuration" "hardened_bucket_lifecycle" {
  bucket = aws_s3_bucket.hardened_bucket.id

  rule {
    id     = "archive-and-expire"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_notification" "hardened_bucket_notification" {
  bucket = aws_s3_bucket.hardened_bucket.id
}

resource "aws_s3_bucket_replication_configuration" "hardened_bucket_replication" {
  count = 0

  bucket = aws_s3_bucket.hardened_bucket.id
  role   = "arn:aws:iam::123456789012:role/s3-replication-role"

  rule {
    id     = "placeholder"
    status = "Enabled"

    destination {
      bucket        = "arn:aws:s3:::devsecops-gatekeeper-replication-placeholder"
      storage_class = "STANDARD"
    }
  }
}

resource "aws_security_group" "hardened_sg" {
  name        = "restricted-ssh-sg"
  description = "Restrict SSH to a trusted admin IP"

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

resource "aws_instance" "hardened_instance" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.hardened_sg.id]
}
