# Specify the GCP Provider
provider "google" {
  project   = var.project_id
  region    = var.region
}

# Create a GCS Bucket
resource "google_storage_bucket" "my_gcs" {
  name          = var.bucket_name
  location      = var.region
  storage_class = var.storage_class
  versioning {
    enabled = var.versioning 
  }
}