resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name  # Inputs the bucket name which is passed via variable bucket_name
  acl    = "private" # Bucket is set as Private means it won’t be accessible publicly 
  region = var.aws_region # This is AWS region where you bucket should reside
  lifecycle {
    prevent_destroy = true # Lifecycle policy set to true for prevent_destroy will help us to avoid any accidental deletion of our bucket
  }
  tags = {
    Name    = var.bucket_name # We can also pass TAGs for our bucket
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256" # We can define encryption type for our bucket 
      }
    }
  }
}
