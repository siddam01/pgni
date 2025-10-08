# S3 Bucket Configuration
# Creates S3 bucket for file uploads with proper security and CORS

# S3 Bucket for file uploads
resource "aws_s3_bucket" "uploads" {
  bucket = "${local.name_prefix}-${var.aws_account_id}-uploads"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-uploads"
    }
  )
}

# Enable versioning
resource "aws_s3_bucket_versioning" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  versioning_configuration {
    status = var.enable_s3_versioning ? "Enabled" : "Suspended"
  }
}

# Configure server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.enable_kms_encryption ? "aws:kms" : "AES256"
      kms_master_key_id = var.enable_kms_encryption ? var.kms_key_id : null
    }
  }
}

# Block public access (we'll use presigned URLs)
resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CORS configuration
resource "aws_s3_bucket_cors_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]  # Update with your app domains in production
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Lifecycle policy (optional - for cost optimization)
resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  rule {
    id     = "transition-to-ia"
    status = var.environment == "production" ? "Enabled" : "Disabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

# Bucket policy to allow EC2 instance to access
resource "aws_s3_bucket_policy" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2Access"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ec2.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.uploads.arn,
          "${aws_s3_bucket.uploads.arn}/*"
        ]
      }
    ]
  })
}

# Store S3 bucket name in SSM
resource "aws_ssm_parameter" "s3_bucket" {
  name        = "/${var.project_name}/${var.environment}/s3/bucket"
  description = "S3 bucket name for uploads"
  type        = "String"
  value       = aws_s3_bucket.uploads.id

  tags = local.common_tags
}

