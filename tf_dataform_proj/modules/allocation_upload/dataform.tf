# Link Dataform project with a GitHub repository
resource "google_dataform_repository" "repository" {
  provider = google-beta
  project  = var.project
  name     = "add_dimensions"
  region   = "europe-west3"
  service_account = "${google_service_account.dataform.email}"

  git_remote_settings {
      url = "https://github.com/dgrzebyk/dataform.git"
      default_branch = "main"
      authentication_token_secret_version = google_secret_manager_secret_version.secret_version.id
  }

  workspace_compilation_overrides {
    default_database = var.project
    schema_suffix = "_suffix"
    table_prefix = "prefix_"
  }
}

# Create a Dataform release configuration
resource "google_dataform_repository_release_config" "release_config" {
  provider = google-beta

  project    = google_dataform_repository.repository.project
  region     = google_dataform_repository.repository.region
  repository = google_dataform_repository.repository.name

  name          = "main"
  git_commitish = "main"

  code_compilation_config {
    default_database = var.project
    default_schema   = "allocation"
    default_location = local.region
    assertion_schema = "allocation_assertions"
    database_suffix  = ""
    schema_suffix    = ""
    table_prefix     = ""
    vars = {
      projectId = var.project
    }
  }
}

# Create a Dataform workflow configuration
resource "google_dataform_repository_workflow_config" "workflow" {
  provider = google-beta

  project        = google_dataform_repository.repository.project
  region         = google_dataform_repository.repository.region
  repository     = google_dataform_repository.repository.name
  name           = "add_dimensions"
  release_config = google_dataform_repository_release_config.release_config.id

  invocation_config {
    service_account = google_service_account.dataform.email
  }
}

# Create BigQuery tables to be populated by Dataform
resource "google_bigquery_dataset" "bigquery_datasets" {
  for_each      = toset(var.bq_datasets)
  dataset_id    = each.value
  friendly_name = each.value
  location      = local.region
  project       = var.project
}
