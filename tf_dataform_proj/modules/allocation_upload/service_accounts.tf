resource "google_service_account" "dataform" {
  account_id   = "dataform-sa"
  display_name = "Dataform Service Account"
}

resource "google_service_account" "cloud_functions" {
  account_id   = "cloud-functions-sa"
  display_name = "Cloud Functions Service Account"
}

resource "google_service_account" "cloud_storage" {
  account_id   = "gcs-sa"
  display_name = "Cloud Storage Service Account"
}

# Allow buckets to send notifications to Pub/Sub topics
data "google_storage_project_service_account" "gcs_account" {
}

resource "google_pubsub_topic_iam_binding" "binding" {
  topic   = google_pubsub_topic.ratios_upload.id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

resource "google_cloudfunctions2_function_iam_member" "invoker" {
  project        = google_cloudfunctions2_function.ratios_to_bq.project
  location       = google_cloudfunctions2_function.ratios_to_bq.location
  cloud_function = google_cloudfunctions2_function.ratios_to_bq.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.cloud_functions.email}"
}

resource "google_cloud_run_service_iam_member" "cloud_run_invoker" {
  project  = google_cloudfunctions2_function.snp_a005_to_bq.project
  location = google_cloudfunctions2_function.snp_a005_to_bq.location
  service  = google_cloudfunctions2_function.snp_a005_to_bq.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.cloud_storage.email}"
}
