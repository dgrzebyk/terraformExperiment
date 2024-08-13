resource "google_pubsub_topic" "ratios_upload" {
  name = "ratios_upload"
}

resource "google_pubsub_topic" "snp_a005_upload" {
  name = "snp_a005_upload"
}
