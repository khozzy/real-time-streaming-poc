#resource "aws_athena_database" "db" {
#  name   = "${var.s3_bucket}_db"
#  bucket = aws_s3_bucket.streaming_data.id
#}