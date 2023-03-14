variable "myip" {
  type    = string
  default = "185.200.83.162/32" # curl ifconfig.io
}

variable "cloudwatch_log_group" {
  type = string
  default = "khozzy/streaming"
}

# S3
variable "s3_sink_bucket_name" {
  type    = string
  default = "khozzy-data-streaming"
}

variable "s3_flink_apps_bucket_name" {
  type    = string
  default = "khozzy-flink-apps"
}

# Kinesis data stream
variable "input_stream_name" {
  type    = string
  default = "stream_in"
}

# Kinesis Delivery
variable "kinesis_delivery_log_stream" {
  type = string
  default = "kinesis-delivery"
}

variable "output_stream_name" {
  type    = string
  default = "stream_out"
}

# Kinesis Analytics
variable "kinesis_analytics_log_stream" {
  type = string
  default = "kinesis-analytics"
}

variable "flink_jar_path" {
  type    = string
#  default = "../my-kda-application/target/original-aws-kinesis-analytics-java-apps-1.0.jar"
  default = "../my-kda-application/target/aws-kinesis-analytics-java-apps-1.0.jar"
}