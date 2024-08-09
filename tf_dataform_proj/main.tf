/******************************************
	Google provider configuration
 *****************************************/

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

variable "project" {
  default = "tf-experiment-426707"
}

variable "region" {
  default = "europe-west3"
}

variable "zone" {
  default = "europe-west3-a"
}

variable "bq_datasets" {
  default = ["allocation", "allocation_assertions"]
}

variable "github_token" {
  default     = "GitHub token"
  type        = string
  sensitive   = true
}
