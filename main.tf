# -------- Provider Setup --------
provider "aws" {
  region = "us-east-1" # change if you want another region
}

# -------- S3 Buckets --------
resource "aws_s3_bucket" "request_bucket" {
  bucket        = "danue-request-bucket-123"
  force_destroy = true
}

resource "aws_s3_bucket" "response_bucket" {
  bucket        = "danue-response-bucket-123"
  force_destroy = true
}

# -------- S3 Bucket Lifecycle Policy (auto delete after 30 days) --------
resource "aws_s3_bucket_lifecycle_configuration" "request_lifecycle" {
  bucket = aws_s3_bucket.request_bucket.id

  rule {
    id     = "expire-requests"
    status = "Enabled"

    filter {
      prefix = "" # apply to all objects
    }

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "response_lifecycle" {
  bucket = aws_s3_bucket.response_bucket.id

  rule {
    id     = "expire-responses"
    status = "Enabled"

    filter {
      prefix = "" # apply to all objects
    }

    expiration {
      days = 30
    }
  }
}

# -------- IAM Role for Lambda + Translate + S3 --------
resource "aws_iam_role" "translate_role" {
  name = "translate-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# -------- IAM Policy --------
resource "aws_iam_policy" "translate_policy" {
  name        = "translate-s3-policy"
  description = "Allow Translate + S3 access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:PutObject"],
        Resource = [
          "${aws_s3_bucket.request_bucket.arn}/*",
          "${aws_s3_bucket.response_bucket.arn}/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = ["translate:*"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

# -------- Attaching Policy to Role --------
resource "aws_iam_role_policy_attachment" "translate_attach" {
  role       = aws_iam_role.translate_role.name
  policy_arn = aws_iam_policy.translate_policy.arn
}

# -------- Attaching AWS Managed Lambda Basic Execution Role --------
resource "aws_iam_role_policy_attachment" "lambda_basic_attach" {
  role       = aws_iam_role.translate_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# -------- Lambda Function --------
resource "aws_lambda_function" "translate_lambda" {
  function_name = "translate-function"
  role          = aws_iam_role.translate_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"

  filename         = "lambda_package.zip"
  source_code_hash = filebase64sha256("lambda_package.zip")

  environment {
    variables = {
      REQUEST_BUCKET  = aws_s3_bucket.request_bucket.bucket
      RESPONSE_BUCKET = aws_s3_bucket.response_bucket.bucket
    }
  }
}

# -------- S3 Event Trigger for Lambda --------
resource "aws_s3_bucket_notification" "request_trigger" {
  bucket = aws_s3_bucket.request_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.translate_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# -------- Allowing S3 to Invoke Lambda --------
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.translate_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.request_bucket.arn
}
