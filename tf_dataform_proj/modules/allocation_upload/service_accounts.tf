data "google_project" "my_project" {
  project_id = var.project
}

### DEFINE CUSTOM SERVICE ACCOUNTS ###
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

### GRANT CLOUD FUNCTIONS PERMISSIONS ###
resource "google_cloudfunctions2_function_iam_member" "cf_invoker" {
  project        = google_cloudfunctions2_function.ratios_to_bq.project
  location       = google_cloudfunctions2_function.ratios_to_bq.location
  cloud_function = google_cloudfunctions2_function.ratios_to_bq.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.cloud_functions.email}"
}

resource "google_cloudfunctions2_function_iam_member" "run_invoker" {
  project        = google_cloudfunctions2_function.ratios_to_bq.project
  location       = google_cloudfunctions2_function.ratios_to_bq.location
  cloud_function = google_cloudfunctions2_function.ratios_to_bq.name
  role           = "roles/run.invoker"
  member         = "serviceAccount:${google_service_account.cloud_functions.email}"
}

### GRANT PERMISSIONS TO THE DEFAULT DATAFORM SERVICE ACCOUNT ###
# Reading secrets is necessary for Dataform to access GitHub Token
resource "google_secret_manager_secret_iam_member" "access" {
  project   = var.project
  secret_id = google_secret_manager_secret.secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.my_project.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

### IMPERSONATE DEFAULT DATAFORM SERVICE ACCOUNT ###
resource "google_service_account_iam_binding" "custom_service_account_token_creator" {
  service_account_id = "projects/${var.project}/serviceAccounts/${google_service_account.dataform.email}"

  role = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:service-${data.google_project.my_project.number}@gcp-sa-dataform.iam.gserviceaccount.com"
  ]
}

resource "google_secret_manager_secret_iam_binding" "github_secret_accessor" {
  secret_id = google_secret_manager_secret.secret.secret_id

  role = "roles/secretmanager.secretAccessor"

  members = [
    "serviceAccount:service-${data.google_project.my_project.number}@gcp-sa-dataform.iam.gserviceaccount.com"
  ]

  depends_on = [
    google_secret_manager_secret.secret
  ]
}

### GRANT CUSTOM DATAFORM SERVICE ACCOUNT THE NECESSARY PERMISSIONS ###
resource "google_project_iam_member" "dataform_roles" {
  for_each = toset([
    "roles/bigquery.dataEditor",
    "roles/bigquery.dataViewer",
    "roles/bigquery.user",
    "roles/bigquery.dataOwner"
  ])

  project = var.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.dataform.email}"

  depends_on = [
    google_service_account.dataform
  ]
}
