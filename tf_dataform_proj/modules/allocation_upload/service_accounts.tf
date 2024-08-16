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

data "google_storage_project_service_account" "gcs_account" {
}

# Grant permissions to GCS SA to receive Eventarc events
resource "google_project_iam_member" "gcs_sa_roles" {
  for_each = toset([
    "roles/eventarc.eventReceiver",
    "roles/run.invoker",
    "roles/pubsub.publisher"
  ])

  project = var.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloud_storage.email}"

  depends_on = [
    google_service_account.cloud_storage
  ]
}

resource "google_project_iam_member" "cloud_function_roles" {
  for_each = toset([
    "roles/cloudfunctions.admin",
    "roles/cloudfunctions.invoker",
    "roles/run.invoker",
    "roles/cloudbuild.builds.builder",
    "roles/storage.objectAdmin",
    "roles/logging.logWriter",
    "roles/bigquery.jobUser",
    "roles/bigquery.dataEditor"
  ])

  project = var.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloud_functions.email}"

  depends_on = [
    google_service_account.cloud_functions
  ]
}

# Dataform does not have this handle yet which is why we had to rely on naming convention
data "google_compute_default_service_account" "default" {
}

resource "google_service_account_iam_member" "cf_sa_impersonation" {
  # User-defined service account to be impersonated
  service_account_id = "projects/${var.project}/serviceAccounts/${google_service_account.cloud_functions.email}"
  role = "roles/iam.serviceAccountTokenCreator"
  # Member is the primary identity that can impersonate user-defined service account
  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

### GRANT DATAFORM PERMISSIONS ###
# Allow default dataform SA to impersonate user-defined dataform SA
resource "google_service_account_iam_member" "custom_service_account_token_creator" {
  service_account_id = "projects/${var.project}/serviceAccounts/${google_service_account.dataform.email}"
  role = "roles/iam.serviceAccountTokenCreator"
  member = "serviceAccount:service-${data.google_project.my_project.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

# Allow default Dataform SA to access GitHub Token - TODO: Why not user-defined SA?
resource "google_secret_manager_secret_iam_member" "access" {
  project   = var.project
  secret_id = google_secret_manager_secret.secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.my_project.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

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
