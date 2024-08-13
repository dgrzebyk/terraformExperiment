resource "google_service_account" "dataform" {
  account_id   = "dataform-sa"
  display_name = "Dataform Service Account"
}

resource "google_service_account" "cloud_functions" {
  account_id   = "cloud-function-sa"
  display_name = "Dataform Service Account"
}
