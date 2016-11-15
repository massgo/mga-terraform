output "logs" {
    value = ["${aws_s3_bucket.logs.bucket}"]
}

output "tf-state" {
    value = ["${aws_s3_bucket.tf-state.bucket}"]
}
