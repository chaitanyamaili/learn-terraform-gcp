provider "google" {
  project = var.project
}

provider "google-beta" {
  project = var.project
}

locals {
  health_check = {
    check_interval_sec  = null
    timeout_sec         = null
    healthy_threshold   = null
    unhealthy_threshold = null
    request_path        = "/"
    port                = 80
    host                = null
    logging             = null
  }
}

# [START cloudloadbalancing_ext_http_gce_plus_bucket]
module "gce-lb-https" {
  source  = "GoogleCloudPlatform/lb-http/google"
  version = "~> 5.1"
  name    = var.load_balancer_name
  project = var.project
  firewall_networks = ["vpc-1-pdk"]
  url_map           = google_compute_url_map.website_url.self_link  
  create_url_map    = false
  create_address = true
  ssl               = true
  managed_ssl_certificate_domains = ["somedomaintobereplaced.com"]

  backends = {
    default = {
      description                     = null
      protocol                        = "HTTP"
      port                            = 80
      port_name                       = "http"
      timeout_sec                     = 10
      connection_draining_timeout_sec = null
      enable_cdn                      = false
      security_policy                 = null
      session_affinity                = null
      affinity_cookie_ttl_sec         = null
      custom_request_headers          = null
      custom_response_headers         = null

      health_check = local.health_check
      log_config = {
        enable      = true
        sample_rate = 1.0
      }
      groups = []

      iap_config = {
        enable               = false
        oauth2_client_id     = ""
        oauth2_client_secret = ""
      }
    }
  }
}

resource "google_compute_url_map" "website_url" {
  // note that this is the name of the load balancer
  name            = var.load_balancer_name
  #default_service = module.gce-lb-https.backend_services["default"].self_link
  default_service = google_compute_backend_bucket.website_backend.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.website_backend.id
  }
}

resource "google_compute_backend_bucket" "website_backend" {
  name        = var.bucket_name
  description = "Contains static resources for example app"
  bucket_name = google_storage_bucket.website.name
  enable_cdn  = false
}

resource "google_storage_bucket" "website" {
  name     = var.bucket_name
  location = "US"

  // delete bucket and contents on destroy.
  force_destroy = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }
}

# To make public bucket
resource "google_storage_bucket_iam_binding" "website_viewers" {
  bucket = google_storage_bucket.website.name
  role   = "roles/storage.objectViewer"
  members = ["allUsers"]
}

# create the index and error page content
resource "google_storage_bucket_object" "website_index" {
  name    = "index.html"
  content = "Welcome to static website!!"
  bucket  = google_storage_bucket.website.name
}
# [END cloudloadbalancing_ext_http_gce_plus_bucket]