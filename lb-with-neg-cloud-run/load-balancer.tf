# Use Google-provided module to define a bucket
provider "google" {
  project = var.project_id
}

# Use Google-provided module to define a bucket
provider "google-beta" {
  project = var.project_id
}

# A 'decoupled-shared-sandbox' cloud storage bucket for backend LB.
#tfsec:ignore:google-storage-no-public-access
module "cloud_storage_load_balancer" {
  source  = "terraform-google-modules/cloud-storage/google"
  version = "~> 3.2"

  project_id = var.project_id
  prefix     = var.prefix
  location   = var.location

  names            = [var.load_balancer_storage]
  set_viewer_roles = true
  viewers = [
    "allUsers"
  ]

  # TO DELETE
  force_destroy = {
    enable = true
  }
  website = {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }
  # TO DELETE
}

# TO DELETE
# create the index and error page content
resource "google_storage_bucket_object" "index_page" {
  name    = "index.html"
  content = "Welcome to static website!!"
  bucket  = module.cloud_storage_load_balancer.name
}
# TO DELETE

# Load balancer configurations
# Backend bucket
resource "google_compute_backend_bucket" "load-balancer-bucket" {
  name    = "${var.load_balancer}-load-balancer-bucket"
  project = var.project_id

  description = "Create the bucket backend for load balancer to use."
  bucket_name = module.cloud_storage_load_balancer.name
}

# Backend network end point (NEG)
resource "google_compute_backend_service" "load-balancer-run-group" {
  name                            = "${var.load_balancer}-load-balancer-backend-service"
  enable_cdn                      = true
  timeout_sec                     = 10
  connection_draining_timeout_sec = 10

  custom_request_headers  = ["host: ${google_compute_global_network_endpoint.proxy.fqdn}"]
  custom_response_headers = ["X-Cache-Hit: {cdn_cache_status}"]

  backend {
    group = google_compute_global_network_endpoint_group.external_proxy.id
  }
}

resource "google_compute_global_network_endpoint_group" "external_proxy" {
  provider              = google-beta
  project               = var.project_id
  name                  = "${var.load_balancer}-network-endpoint"
  network_endpoint_type = "INTERNET_FQDN_PORT"
  default_port          = "443"
}

resource "google_compute_global_network_endpoint" "proxy" {
  provider                      = google-beta
  project                       = var.project_id
  global_network_endpoint_group = google_compute_global_network_endpoint_group.external_proxy.id
  fqdn                          = trimprefix(data.google_cloud_run_service.run_service.status[0].url  , "https://")
  port                          = google_compute_global_network_endpoint_group.external_proxy.default_port
}


# External IP Address for load balancer
resource "google_compute_global_address" "static-ip-address" {
  name    = "${var.load_balancer}-static-ip"
  project = var.project_id

  description = "The static ip address to use for the load balancer."
}

resource "google_compute_global_forwarding_rule" "https-rule" {
  name    = "${var.load_balancer}-https-proxy-rule"
  project = var.project_id

  target     = google_compute_target_https_proxy.https-proxy.id
  port_range = "443"

  ip_address = google_compute_global_address.static-ip-address.id
}

resource "google_compute_global_forwarding_rule" "static_http" {
  name    = "${var.load_balancer}-http-proxy-rule"
  project = var.project_id

  target     = google_compute_target_http_proxy.http-proxy.id
  port_range = "80"

  ip_address = google_compute_global_address.static-ip-address.id
}

# Managed SSL Certificates
resource "google_compute_managed_ssl_certificate" "load-balancer-certificate" {
  name    = "${var.load_balancer}-load-balancer-certificate"
  project = var.project_id

  managed {
    domains = [var.load_balancer_domain]
  }
}

# Load balancer
resource "google_compute_url_map" "load-balancer" {
  name    = "${var.load_balancer}-load-balancer"
  project = var.project_id

  default_service = google_compute_backend_bucket.load-balancer-bucket.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.load-balancer-bucket.id

    path_rule {
      paths   = ["/site/*"]
      service = google_compute_backend_bucket.load-balancer-bucket.id
    }

    path_rule {
      paths   = ["/cloud-run1/*"]
      service = google_compute_backend_service.load-balancer-run-group.id
    } 
  }
}

resource "google_compute_target_https_proxy" "https-proxy" {
  name    = "${var.load_balancer}-https-proxy"
  project = var.project_id

  url_map          = google_compute_url_map.load-balancer.id
  ssl_certificates = [google_compute_managed_ssl_certificate.load-balancer-certificate.id]
}

resource "google_compute_target_http_proxy" "http-proxy" {
  name    = "${var.load_balancer}-http-proxy"
  project = var.project_id

  url_map = google_compute_url_map.load-balancer.id
}
