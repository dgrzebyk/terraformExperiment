resource "google_storage_bucket" "allocation_excels" {
  name     = "allocation_excels"
  location = local.region
}

resource "google_storage_bucket" "snp_a005_reports" {
  name     = "snp_a005_reports"
  location = local.region
}

resource "google_storage_bucket" "sap_txts" {
  name     = "sap_txts"
  location = local.region
}

# Defining bucket containing cloud functions code
resource "google_storage_bucket" "cf_allocation_upload" {
  name     = "cf_allocation_upload"
  location = local.region
}

# Storing cloud function code in a GCS bucket
resource "google_storage_bucket_object" "zip_files" {
  for_each = {
    "allocation_ratios.zip" = "../cloud_functions/allocation_ratios.zip",
    "bq_to_txt.zip"         = "../cloud_functions/bq_to_txt.zip",
    "snp_a005.zip"          = "../cloud_functions/snp_a005.zip"
  }

  name   = each.key            # the file name
  bucket = google_storage_bucket.cf_allocation_upload.name
  source = each.value          # the file path
}

