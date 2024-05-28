provider "aws" {
  default_tags {
    tags = {
      Environment = "Dev"
    Project = "Matrix" }
  }
}