# Defining bucket containing data
resource "google_storage_bucket" "allocation_upload" {
  name     = "allocation_upload"
  location = local.region
}

# Defining bucket containing cloud functions code
resource "google_storage_bucket" "cf_allocation_upload" {
  name     = "cf_allocation_upload"
  location = local.region
}

# Creating 3 folders in the data bucket
resource "google_storage_bucket_object" "snp_a005_reports" {
  name   = "snp_a005_reports/" # folder name should end with '/'
  content = " "            # content is ignored but should be non-empty
  bucket = google_storage_bucket.allocation_upload.name
}

resource "google_storage_bucket_object" "ratios" {
  name   = "ratios/" # folder name should end with '/'
  content = " "            # content is ignored but should be non-empty
  bucket = google_storage_bucket.allocation_upload.name
}

resource "google_storage_bucket_object" "txts" {
  name   = "txts/" # folder name should end with '/'
  content = " "            # content is ignored but should be non-empty
  bucket = google_storage_bucket.allocation_upload.name
}

# ### BUCKET NOTIFICATIONS TO PUB/SUB ###
# # Configure GCS bucket notification to publish to the Pub/Sub topic
# resource "google_storage_notification" "ratios_upload" {
#   bucket = google_storage_bucket.allocation_upload.name
#   payload_format = "JSON_API_V1"
#   topic  = google_pubsub_topic.ratios_upload.id
#   event_types = ["OBJECT_FINALIZE"]
#   object_name_prefix = "ratios/"
#   depends_on = [google_pubsub_topic_iam_binding.binding]
# }
#
# # Configure GCS bucket notification to publish to the Pub/Sub topic
# resource "google_storage_notification" "snp_a005_upload" {
#   bucket = google_storage_bucket.allocation_upload.name
#   payload_format = "JSON_API_V1"
#   topic  = google_pubsub_topic.snp_a005_upload.id
#   event_types = ["OBJECT_FINALIZE"]
#   object_name_prefix = "snp_a005_reports/"
#   depends_on = [google_pubsub_topic_iam_binding.binding]
# }

### CLOUD FUNCTIONS CODE ###
# Stores cloud function code in a GCS bucket
resource "google_storage_bucket_object" "cloud_function_ratios" {
  name   = "allocation_ratios.zip"
  bucket = google_storage_bucket.cf_allocation_upload.name
  # source - path to zip file containing the code from this repository root
  source = "cloud_functions/allocation_ratios.zip"
}

# # Stores cloud function code in a GCS bucket
# resource "google_storage_bucket_object" "cloud_function_snp_a005" {
#   name   = "snp_a005.zip"
#   bucket = google_storage_bucket.cf_allocation_upload.name
#   # source - path to zip file containing the code from this repository root
#   source = "../cloud_functions/snp_a005.zip"
# }
#
# # Stores cloud function code in a GCS bucket
# resource "google_storage_bucket_object" "cloud_function_bq_to_txt" {
#   name   = "bq_to_txt.zip"
#   bucket = google_storage_bucket.cf_allocation_upload.name
#   # source - path to zip file containing the code from this repository root
#   source = "../cloud_functions/bq_to_txt.zip"
# }
