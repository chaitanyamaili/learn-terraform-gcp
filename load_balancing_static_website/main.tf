# Use Google-provided module to define a bucket
provider "google" {
  project   = var.project
}

module "cloud_storage_buckets" {
  source  = "terraform-google-modules/cloud-storage/google"
  version = "~> 3.2"

  project_id       = var.project
  prefix           = var.prefix
  location         = var.bucket_location
  names            = [var.bucket_name]
  set_viewer_roles = true
  viewers = [
    "allUsers"
  ]
  website = {
    main_page_suffix = "index.html"
    not_found_page   = "error.html"
  }
}

# create the index and error page content
resource "google_storage_bucket_object" "index_page" {
  name    = "index.html"
  content = "Welcome to static website!!"
  bucket  = module.cloud_storage_buckets.name
}

resource "google_storage_bucket_object" "error_page" {
  name    = "error.html"
  content = "Uh oh"
  bucket  = module.cloud_storage_buckets.name
}

# External IP Address for load balancer
resource "google_compute_global_address" "static" {
  name        = "${var.prefix}-static"
  project     = var.project
  description = "Static external IP address for hosting"
}

# SSL Certificates
resource "google_compute_managed_ssl_certificate" "default" {
  name    = "${var.prefix}-cert"
  project = var.project

  managed {
    domains = ["somedomaintobereplaced.com"]
  }
}

# HTTPS load balancer for backend bucket
resource "google_compute_backend_bucket" "static" {
  name        = "${var.prefix}-${var.bucket_name}"
  project     = var.project
  description = "Backend storage bucket for statick static files"
  bucket_name = module.cloud_storage_buckets.name
  enable_cdn  = false
}

# Load balancer
resource "google_compute_url_map" "static" {
  name            = "${var.prefix}-${var.environment}-${var.lb_name}"
  project         = var.project
  default_service = google_compute_backend_bucket.static.id
}

resource "google_compute_target_https_proxy" "static" {
  name             = "${var.prefix}-${var.environment}-static"
  project          = var.project
  url_map          = google_compute_url_map.static.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}

resource "google_compute_global_forwarding_rule" "static" {
  name       = "${var.prefix}-${var.environment}-static"
  project    = var.project
  target     = google_compute_target_https_proxy.static.id
  port_range = "443"
  ip_address = google_compute_global_address.static.id
}

resource "google_compute_target_http_proxy" "static" {
  name    = "${var.prefix}-${var.environment}-static-http-proxy"
  project = var.project
  url_map = google_compute_url_map.static.id
}

resource "google_compute_global_forwarding_rule" "static_http" {
  name       = "${var.prefix}-${var.environment}-static-forwarding-rule-http"
  project    = var.project
  target     = google_compute_target_http_proxy.static.id
  port_range = "80"
  ip_address = google_compute_global_address.static.id
}
