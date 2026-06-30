terraform {
  required_version = ">= 1.3.0, < 2.0.0"

  backend "gcs" {}

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.38.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.region
}
