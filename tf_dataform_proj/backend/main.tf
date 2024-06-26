/******************************************
	Variables and Locals
 *****************************************/

variable "project" {
  description = "GCP project name"
  type        = string
}

locals {
  region = "europe-west3"
  zone   = "europe-west3-a"
}

/******************************************
	Google provider configuration
 *****************************************/

provider "google" {
  project = var.project
  region  = local.region
  zone    = local.zone
}

/******************************************
  State storage configuration
 *****************************************/

resource "google_storage_bucket" "terraform_state" {
  name                        = "${var.project}_terraform"
  location                    = local.region
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  force_destroy = true
}