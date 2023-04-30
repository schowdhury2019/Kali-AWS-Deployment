terraform {
  backend "s3" {
    bucket  = "hackers-playground"
    key     = "hp.tfstate"
    region  = "eu-west-1"
    profile = "tf_user"
  }
}