provider "aws" {
  region  = "us-east-1"
  version = "~> 1.6"
}
    
terraform {
  backend "s3" {
    bucket     = "${var.bucket_testing}"
    kms_key_id = "arn:aws:kms:us-east-1:12345678900:key/12312313ed-34sd-6sfa-90cvs-1234asdfasd"
    key     = "testexport/exportFile.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
    
data "aws_s3_bucket" "pr-ip" {
  bucket = "${var.bucket_testing}"
}
    
resource "aws_s3_bucket_object" "put_file" {
  bucket = "${data.aws_s3_bucket.pr-ip.id}"
  key    = "${var.file_path}/${var.file_name}"
  source = "src/Datafile.txt"
  etag = "${md5(file("src/Datafile.txt"))}"
    
  kms_key_id = "arn:aws:kms:us-east-1:12345678900:key/12312313ed-34sd-6sfa-90cvs-1234asdfasd"
  server_side_encryption = "aws:kms"
}