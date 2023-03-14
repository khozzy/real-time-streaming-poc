resource "aws_kinesis_stream" "input_stream" {
  name             = var.input_stream_name
  shard_count      = 1
  retention_period = 48

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}

output "kinesis_input_stream_name" {
  value = aws_kinesis_stream.input_stream.name
}