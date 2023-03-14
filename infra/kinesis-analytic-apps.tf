data "aws_iam_policy_document" "kinesis_analytics_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["kinesisanalytics.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "kinesis_analytics_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.flink_apps.arn}/${aws_s3_object.flink_s3_app_obj.key}"]
  }
  statement {
    actions = [
      "s3:Abort*",
      "s3:DeleteObject*",
      "s3:GetObject*",
      "s3:GetBucket*",
      "s3:List*",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.sink_bucket.arn,
      "${aws_s3_bucket.sink_bucket.arn}/*"
    ]
  }
  statement {
    actions   = ["logs:PutLogEvents"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${var.cloudwatch_log_group}:log-stream:${var.kinesis_analytics_log_stream}"]
  }
  statement {
    actions   = ["kinesis:*"]
    resources = [aws_kinesis_stream.input_stream.arn]
  }
#  statement {
#    actions   = ["firehose:*"]
#    resources = [aws_kinesis_firehose_delivery_stream.output_stream.arn]
#  }
}

resource "aws_iam_role" "kinesis_analytics_role" {
  name               = "kinesis_analytics_assume_role"
  assume_role_policy = data.aws_iam_policy_document.kinesis_analytics_assume_role.json
  inline_policy {
    name   = "flink-policy"
    policy = data.aws_iam_policy_document.kinesis_analytics_policy.json
  }
}

resource "aws_s3_bucket" "flink_apps" {
  bucket = var.s3_flink_apps_bucket_name
}

resource "aws_s3_object" "flink_s3_app_obj" {
  bucket = aws_s3_bucket.flink_apps.id
  key    = "app.jar"
  acl    = "private"
  source = var.flink_jar_path
  etag   = filemd5(var.flink_jar_path)
}

resource "aws_kinesisanalyticsv2_application" "flink_app" {
  name                   = "example-flink-app"
  description            = "Let's get it rolling - s3 stream!"
  runtime_environment    = "FLINK-1_15"
  service_execution_role = aws_iam_role.kinesis_analytics_role.arn

  start_application = true

  cloudwatch_logging_options {
    log_stream_arn = aws_cloudwatch_log_stream.kinesis_analytics_log_stream.arn
  }

  application_configuration {
    application_code_configuration {
      code_content {
        s3_content_location {
          bucket_arn = aws_s3_bucket.flink_apps.arn
          file_key   = aws_s3_object.flink_s3_app_obj.key
        }
      }

      code_content_type = "ZIPFILE"
    }

    flink_application_configuration {
      checkpoint_configuration {
        configuration_type = "DEFAULT"
      }

      monitoring_configuration {
        configuration_type = "CUSTOM"
        log_level          = "DEBUG"
        metrics_level      = "TASK"
      }

      parallelism_configuration {
        auto_scaling_enabled = false
        configuration_type   = "CUSTOM"
        parallelism          = 1
        parallelism_per_kpu  = 1
      }
    }
  }
}