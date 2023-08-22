terraform {
  required_version = "~> 1.4.0"

  backend "gcs" {
    bucket = "aw-deployment-terraform-state-rules-js"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = "aw-deployment-rules-js"
  region  = "us-west2"
}
