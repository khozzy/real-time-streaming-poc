# https://docs.aws.amazon.com/kinesisanalytics/latest/java/get-started-exercise-fh.html
# https://github.com/aws-samples/amazon-kinesis-data-analytics-examples/blob/master/FirehoseSink/src/main/java/com/amazonaws/services/kinesisanalytics/FirehoseSinkStreamingJob.java

# S3 sink config
data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# https://docs.aws.amazon.com/firehose/latest/dev/controlling-access.html
# https://docs.aws.amazon.com/firehose/latest/dev/controlling-access.html#using-iam-s3
data "aws_iam_policy_document" "kinesis_firehose_delivery_policy" {
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.sink_bucket.arn,
      "${aws_s3_bucket.sink_bucket.arn}/*",
    ]
  }
  statement {
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards"
    ]
    resources = [
      "arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/${var.output_stream_name}"
    ]
  }
  statement {
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${var.cloudwatch_log_group}:log-stream:${var.kinesis_delivery_log_stream}"
    ]
  }
}

resource "aws_s3_bucket" "sink_bucket" {
  bucket = var.s3_sink_bucket_name
}

resource "aws_s3_bucket_acl" "sink_bucket_acl" {
  bucket = aws_s3_bucket.sink_bucket.id
  acl    = "private"
}

resource "aws_iam_role" "firehose_delivery_role" {
  name               = "firehose_delivery_assume_role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
  inline_policy {
    name   = "s3_access"
    policy = data.aws_iam_policy_document.kinesis_firehose_delivery_policy.json
  }
}

# Kinesis config
resource "aws_kinesis_firehose_delivery_stream" "output_stream" {
  name        = var.output_stream_name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose_delivery_role.arn
    bucket_arn          = aws_s3_bucket.sink_bucket.arn
    error_output_prefix = "errors-"

    buffer_size     = 1  # mb
    buffer_interval = 60 # sec

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.log_group.name
      log_stream_name = aws_cloudwatch_log_stream.kinesis_delivery_log_stream.name
    }
  }
}