resource "google_project_service" "enabled_apis" {
  project  = var.project
  for_each = toset([
    "bigquery.googleapis.com",
    "cloudfunctions.googleapis.com",
    "dataform.googleapis.com"
  ])
  service  = each.key

  disable_on_destroy = false
}

/******************************************
	Modules
 *****************************************/

module "allocation_upload" {
  source = "./modules/allocation_upload"
  project = var.project

  alerting_google_group_emails = var.alerting_google_group_emails
  bq_datasets = var.bq_datasets
  github_token = var.github_token
}
