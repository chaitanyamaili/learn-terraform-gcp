# Specify the GCP Provider
provider "google" {
  project   = var.project_id
  region    = var.region
}

# Create a GCS Bucket
resource "google_storage_bucket" "static" {
  name                        = var.bucket_name
  location                    = var.region
  storage_class               = var.storage_class
  uniform_bucket_level_access = false
  force_destroy               = true
  versioning {
    enabled = var.versioning 
  }
  website {
    main_page_suffix = "index.html"
    not_found_page   = "error.html"
  }
}

resource "google_storage_default_object_acl" "website_acl" {
  bucket      = google_storage_bucket.static.name
  role_entity = ["READER:allUsers"]
}

resource "google_storage_bucket_object" "index_page" {
  name    = "index.html"
  content = "Hello, World!"
  bucket  = google_storage_bucket.static.name
}

resource "google_storage_bucket_object" "error_page" {
  name    = "error.html"
  content = "Uh oh"
  bucket  = google_storage_bucket.static.name
}
