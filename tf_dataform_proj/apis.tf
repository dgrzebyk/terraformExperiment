resource "google_project_service" "enabled_apis" {
  project  = var.project
  for_each = toset([
    "bigquery.googleapis.com",
    "dataform.googleapis.com",
    "cloudfunctions.googleapis.com",
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "eventarc.googleapis.com",
    "pubsub.googleapis.com"
  ])
  service  = each.key

  disable_on_destroy = false
}
