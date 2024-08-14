# Create the GitHub token secret
resource "google_secret_manager_secret" "secret" {
  provider  = google-beta
  project   = var.project
  secret_id = "github_token"

  replication {
    auto {}
  }
}

# Add the token to the secret
resource "google_secret_manager_secret_version" "secret_version" {
  provider = google-beta
  secret   = google_secret_manager_secret.secret.id

  secret_data = var.github_token
}
