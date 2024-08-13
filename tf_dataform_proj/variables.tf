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

variable "alerting_google_group_emails" {
  description = "List of email addresses for sending alerts"
  type        = list(string)
}

locals {
  region = "europe-west3"
  zone   = "europe-west3-a"
}
