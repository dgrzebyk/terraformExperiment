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

### CLOUD FUNCTIONS CODE ###
# Stores cloud function code in a GCS bucket
resource "google_storage_bucket_object" "cloud_function_ratios" {
  name   = "allocation_ratios.zip"
  bucket = google_storage_bucket.cf_allocation_upload.name
  # source - path to zip file containing the code from this repository root
  source = "cloud_functions/allocation_ratios.zip"
}
