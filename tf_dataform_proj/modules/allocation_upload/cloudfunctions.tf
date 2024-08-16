data "archive_file" "functions_zips" {
  for_each = toset([
    "allocation_ratios",
    "bq_to_txt",
    "snp_a005"
  ])

  type        = "zip"
  output_path = "../cloud_functions/${each.key}.zip"
  source_dir  = "../cloud_functions/${each.key}"
}

# Deploys cloud function uploading allocation ratios to BigQuery
resource "google_cloudfunctions2_function" "ratios_to_bq" {
  name = "ratios_to_bq"
  location = local.region
  description = "Uploading data from .xlsx to BigQuery"

  build_config {
    runtime = "python311"
    entry_point = "allocation_ratios"  # Set the entry point
    service_account = "projects/${var.project}/serviceAccounts/${google_service_account.cloud_functions.email}"
    source {
      storage_source {
        bucket = google_storage_bucket.cf_allocation_upload.name
        object = google_storage_bucket_object.zip_files["allocation_ratios.zip"].name
      }
    }
  }

  service_config {
    max_instance_count  = 1
    available_memory    = "512M"
    timeout_seconds     = 60
    service_account_email = google_service_account.cloud_functions.email
    environment_variables = {
      GOOGLE_CLOUD_PROJECT_ID = var.project
      BQ_DATASET = google_bigquery_dataset.allocation.dataset_id
      BQ_TABLE = google_bigquery_table.ratios_temp.table_id
    }
  }

  event_trigger {
    event_type = "google.cloud.storage.object.v1.finalized"
    retry_policy = "RETRY_POLICY_RETRY"
    service_account_email = google_service_account.cloud_storage.email
    event_filters {
      attribute = "bucket"
      value = google_storage_bucket.allocation_excels.name
    }
  }
}

resource "google_cloudfunctions2_function" "snp_a005_to_bq" {
  name = "snp_a005_to_bq"
  location = local.region
  description = "Copying data from SNP_A005 BISS BOA .xlsx reports to BigQuery"

  build_config {
    runtime = "python311"
    entry_point = "save_snp_a005_to_bq"
    service_account = "projects/${var.project}/serviceAccounts/${google_service_account.cloud_functions.email}"
    source {
      storage_source {
        bucket = google_storage_bucket.cf_allocation_upload.name
        object = google_storage_bucket_object.zip_files["snp_a005.zip"].name
      }
    }
  }

  service_config {
    max_instance_count  = 1
    available_memory    = "512M"
    timeout_seconds     = 60
    service_account_email = google_service_account.cloud_functions.email
    environment_variables = {
      GOOGLE_CLOUD_PROJECT_ID = var.project
      BQ_DATASET = google_bigquery_dataset.allocation.dataset_id
      BQ_TABLE = google_bigquery_table.SNP_A005.table_id
    }
  }

  event_trigger {
    event_type = "google.cloud.storage.object.v1.finalized"
    retry_policy = "RETRY_POLICY_RETRY"
    service_account_email = google_service_account.cloud_storage.email
    event_filters {
      attribute = "bucket"
      value = google_storage_bucket.snp_a005_reports.name
    }
  }
}

# resource "google_cloudfunctions2_function" "bq_to_txt" {
#   name = "bq_to_txt"
#   location = local.region
#   description = "Copying Dataform output from BigQuery to SAP-compatible .txt files"
#
#   build_config {
#     runtime = "python311"
#     entry_point = "bq_to_txt"
#     source {
#       storage_source {
#         bucket = google_storage_bucket.cf_allocation_upload.name
#         object = google_storage_bucket_object.zip_files["bq_to_txt.zip"].name
#       }
#     }
#   }
#
#   service_config {
#     max_instance_count  = 1
#     available_memory    = "256M"
#     timeout_seconds     = 60
#     service_account_email = google_service_account.cloud_functions.email
#   }
#
#   event_trigger {
#     event_type = "google.cloud.storage.object.v1.finalized"
#     retry_policy = "RETRY_POLICY_RETRY"
# #     service_account_email = "${data.google_storage_project_service_account.gcs_account.email_address}"
#     event_filters {
#       attribute = "bucket"
#       value = google_storage_bucket.allocation_upload.name
#     }
#   }
# }
