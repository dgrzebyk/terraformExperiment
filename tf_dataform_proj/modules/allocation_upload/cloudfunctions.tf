# Deploys cloud function uploading allocation ratios to BigQuery
resource "google_cloudfunctions2_function" "ratios_to_bq" {
  name = "ratios_to_bq"
  location = local.region
  description = "Uploading data from .xlsx to BigQuery"

  build_config {
    runtime = "python311"
    entry_point = "allocation_ratios"  # Set the entry point
    source {
      storage_source {
        bucket = google_storage_bucket.cf_allocation_upload.name
        object = google_storage_bucket_object.cloud_function_ratios.name
      }
    }
  }

  service_config {
    max_instance_count  = 1
    available_memory    = "512M"
    timeout_seconds     = 60
    service_account_email = google_service_account.cloud_functions.email
  }

  event_trigger {
    event_type = "google.cloud.storage.object.v1.finalized"
    retry_policy = "RETRY_POLICY_RETRY"
    service_account_email = google_service_account.cloud_storage.email
    event_filters {
      attribute = "bucket"
      value = google_storage_bucket.allocation_upload.name
    }
#     trigger_region = local.region
#     event_type = "google.cloud.pubsub.topic.v1.messagePublished"
#     pubsub_topic = google_pubsub_topic.ratios_upload.id
#     retry_policy = "RETRY_POLICY_RETRY"
  }
}

resource "google_cloudfunctions2_function" "snp_a005_to_bq" {
  name = "snp_a005_to_bq"
  location = local.region
  description = "Uploading data from BISS BOA SNP_A005 report to BigQuery"

  build_config {
    runtime = "python311"
    entry_point = "save_snp_a005_to_bq"  # Set the entry point
    source {
      storage_source {
        bucket = google_storage_bucket.cf_allocation_upload.name
        object = google_storage_bucket_object.cloud_function_snp_a005.name
      }
    }
  }

  service_config {
    max_instance_count  = 1
    available_memory    = "512M"
    timeout_seconds     = 60
    service_account_email = google_service_account.cloud_functions.email
  }

  event_trigger {
    event_type = "google.cloud.storage.object.v1.finalized"
    retry_policy = "RETRY_POLICY_RETRY"
    service_account_email = google_service_account.cloud_storage.email
    event_filters {
      attribute = "bucket"
      value = google_storage_bucket.allocation_upload.name
    }
#     trigger_region = local.region
#     event_type = "google.cloud.pubsub.topic.v1.messagePublished"
#     pubsub_topic = google_pubsub_topic.snp_a005_upload.id
#     retry_policy = "RETRY_POLICY_RETRY"
  }
}

# This cloud function is triggered manually by the user
# resource "google_cloudfunctions2_function" "bq_to_txt" {
#   name = "bq_to_txt"
#   location = local.region
#   description = "Transferring allocations from BigQuery to .txt files in GCS"
#
#   build_config {
#     runtime = "python311"
#     entry_point = "bq_to_txt"  # Set the entry point
#     source {
#       storage_source {
#         bucket = google_storage_bucket.cf_allocation_upload.name
#         object = google_storage_bucket_object.cloud_function_bq_to_txt.name
#       }
#     }
#   }
#
#   service_config {
#     max_instance_count  = 1
#     available_memory    = "256M"
#     timeout_seconds     = 60
#     service_account_email = google_service_account.cloud_storage.email
#   }

#   event_trigger {
#     trigger_region = local.region
#     event_type = "google.cloud.pubsub.topic.v1.messagePublished"
#     pubsub_topic = google_pubsub_topic.snp_a005_upload.id
#     retry_policy = "RETRY_POLICY_RETRY"
#   }
# }
