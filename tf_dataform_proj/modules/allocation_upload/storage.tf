resource "google_storage_bucket" "allocation_upload" {
  name     = "allocation_upload"
  location = local.region
}

resource "google_storage_bucket" "cf_allocation_upload" {
  name     = "cf_allocation_upload"
  location = local.region
}

# Stores cloud function code in a GCS bucket
# resource "google_storage_bucket_object" "archive" {
#   name   = "index.zip"
#   bucket = google_storage_bucket.cf_code.name
#   source = "./path/to/zip/file/which/contains/code"
# }

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
