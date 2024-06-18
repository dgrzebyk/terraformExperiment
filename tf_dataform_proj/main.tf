terraform {
  required_providers {
    google-beta = {
      source = "hashicorp/google-beta"
      version = "5.33.0"
    }
  }
}

# Create the GitHub token secret
resource "google_secret_manager_secret" "secret" {
  provider  = google-beta
  project   = var.project
  secret_id = "github_token"

  replication {
    auto {}
  }
}

# Add the token to the secret
resource "google_secret_manager_secret_version" "secret_version" {
  provider = google-beta
  secret   = google_secret_manager_secret.secret.id

  secret_data = var.github_token
}

resource "google_dataform_repository" "repository" {
  provider = google-beta
  project  = var.project
  name     = "add_dimensions"
  region   = "europe-west3"
#   service_account = google_service_account.dataform_sa.email

  git_remote_settings {
      url = "https://github.com/dgrzebyk/dataform.git"
      default_branch = "main"
      authentication_token_secret_version = google_secret_manager_secret_version.secret_version.id
  }

  workspace_compilation_overrides {
    default_database = "database"
    schema_suffix = "_suffix"
    table_prefix = "prefix_"
  }
}

resource "google_dataform_repository_release_config" "release_config" {
  provider = google-beta

  project    = google_dataform_repository.repository.project
  region     = google_dataform_repository.repository.region
  repository = google_dataform_repository.repository.name

  name          = "main"
  git_commitish = "main"
  cron_schedule = "0 9 * * WED"
  time_zone     = "Europe/Brussels"

  code_compilation_config {
    default_database = var.project
    default_schema   = "allocation"
    default_location = var.region
    assertion_schema = "allocation_assertions"
    database_suffix  = ""
    schema_suffix    = ""
    table_prefix     = ""
    vars = {
      projectId = var.project
    }
  }
}

# resource "google_service_account" "dataform_sa" {
#   provider     = google-beta
#   project      = var.project
#   account_id   = "dataform-sa"
#   display_name = "Dataform Service Account"
# }

resource "google_dataform_repository_workflow_config" "workflow" {
  provider = google-beta

  project        = google_dataform_repository.repository.project
  region         = google_dataform_repository.repository.region
  repository     = google_dataform_repository.repository.name
  name           = "add_dimensions"
  release_config = google_dataform_repository_release_config.release_config.id

  invocation_config {
    included_targets {
      name     = "target_1"
    }
    included_tags                            = ["tag_1"]
    transitive_dependencies_included         = true
    transitive_dependents_included           = true
    fully_refresh_incremental_tables_enabled = false
#     service_account                          = google_service_account.dataform_sa.email
  }

  cron_schedule   = "15 9 * * WED"
  time_zone       = "Europe/Brussels"
}

# Creating BigQuery tables to be populated by Dataform
resource "google_bigquery_dataset" "bq_datasets" {
  for_each      = toset(var.bq_datasets)
  dataset_id    = each.value
  friendly_name = each.value
  location      = var.region
  project       = var.project
}

# Assign Dataform account a Dataform Editor role
# resource "google_project_iam_member" "dataform_sa_iam" {
#   provider = google-beta
#   project  = var.project
#   role     = "roles/dataform.serviceAgent"
#   member   = "serviceAccount:${google_service_account.dataform_sa.email}"
# }

# Assign Dataform account a BigQuery Job User role
resource "google_project_iam_member" "bq_user" {
  provider = google-beta
  project  = var.project
  role     = "roles/bigquery.jobUser"
  member   = "serviceAccount:service-104387202021@gcp-sa-dataform.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "data_editor" {
  provider = google-beta
  project  = var.project
  role     = "roles/bigquery.dataEditor"
  member   = "serviceAccount:service-104387202021@gcp-sa-dataform.iam.gserviceaccount.com"
}

# resource "google_project_iam_member" "secrets_access" {
#   provider = google-beta
#   project  = var.project
#   role     = "roles/secretmanager.secretAccessor"
#   member   = "serviceAccount:${google_service_account.dataform_sa.email}"
# }

# Grant the service account access to read the secret
resource "google_secret_manager_secret_iam_member" "access" {
  project   = var.project
  secret_id = google_secret_manager_secret.secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-104387202021@gcp-sa-dataform.iam.gserviceaccount.com"
}
