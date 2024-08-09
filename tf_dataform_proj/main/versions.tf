terraform {
  required_version = ">= 1.0.0"

  required_providers {
    google = {
      source = "hashicorp/google"
    }
    google-beta = {
      source = "hashicorp/google-beta"
      version = "5.33.0"
    }
  }
}
