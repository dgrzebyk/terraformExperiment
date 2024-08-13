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

### Bucket Notifications ###
# Configure GCS bucket notification to publish to the Pub/Sub topic
resource "google_storage_notification" "allocation_upload" {
  bucket = google_storage_bucket.allocation_upload.name
  payload_format = "JSON_API_V1"
  topic  = google_pubsub_topic.snp_a005_upload.id
  event_types = ["OBJECT_FINALIZE"]
  depends_on = [google_pubsub_topic_iam_binding.binding]
}
