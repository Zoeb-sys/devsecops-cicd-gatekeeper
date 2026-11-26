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
      sse_algorithm = "AES256"
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
