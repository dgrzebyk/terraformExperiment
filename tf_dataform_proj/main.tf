module "allocation_upload" {
  source = "./modules/allocation_upload"
  project = var.project

  alerting_google_group_emails = var.alerting_google_group_emails
  bq_datasets = var.bq_datasets
  github_token = var.github_token
}
