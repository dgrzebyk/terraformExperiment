/******************************************
	Google provider configuration
 *****************************************/

provider "google" {
  project = var.project
  region  = local.region
  zone    = local.zone
}

provider "google-beta" {
  project = var.project
  region  = local.region
  zone    = local.zone
}


/******************************************
	Variables and Locals
 *****************************************/

variable "project" {
  description = "GCP project name"
  type        = string
}

variable "bq_datasets" {
  default = ["allocation", "allocation_assertions"]
}

variable "github_token" {
  type        = string
  sensitive   = true
}

locals {
  region  = "europe-west3"
  zone    = "europe-west3-a"
}
