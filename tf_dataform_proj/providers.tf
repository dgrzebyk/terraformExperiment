provider "google" {
  project = var.project
  region  = local.region
  zone    = local.zone
}

provider "google-beta" {
  project = var.project
  region  = local.region
  zone    = local.zone
}
