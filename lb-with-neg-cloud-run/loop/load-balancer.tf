# Use Google-provided module to define a bucket
provider "google" {
  project = var.project_id
}

# Use Google-provided module to define a bucket
provider "google-beta" {
  project = var.project_id
}

# Get the data from cloud run.
data "google_cloud_run_service" "run_service" {
  count    = length(var.load_balancer_cloud_run_services)
  name     = var.load_balancer_cloud_run_services[count.index].name
  project  = var.load_balancer_cloud_run_services[count.index].project
  location = var.load_balancer_cloud_run_services[count.index].location
}

locals {
  domains             = [for service_domain in var.load_balancer_cloud_run_services : "${service_domain.name}.${var.load_balancer_domain}"]
  load_balancer_count = var.load_balancer != "" ? 1 : 0
  # domains = concat([var.load_balancer_domain], [for service_domain in var.load_balancer_cloud_run_services : "${service_domain.name}.${var.load_balancer_domain}"])
}

# A 'decoupled-shared-sandbox' cloud storage bucket for backend LB.
#tfsec:ignore:google-storage-no-public-access
module "cloud_storage_load_balancer" {
  source  = "terraform-google-modules/cloud-storage/google"
  version = "~> 3.2"
  count   = local.load_balancer_count

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
  count   = local.load_balancer_count
  content = "Welcome to static website!!"
  bucket  = module.cloud_storage_load_balancer[count.index].name
}
# TO DELETE

# Load balancer configurations
# Backend bucket
resource "google_compute_backend_bucket" "load-balancer-bucket" {
  count   = local.load_balancer_count
  name    = "${var.load_balancer}-load-balancer-bucket"
  project = var.project_id

  description = "Create the bucket backend for load balancer to use."
  bucket_name = module.cloud_storage_load_balancer[count.index].name
}

# Backend network end point group1 (NEG)
resource "google_compute_backend_service" "load-balancer-run-service" {
  count      = local.load_balancer_count
  name       = "${var.load_balancer}-load-balancer-backend-service"
  project    = var.project_id
  enable_cdn = false

  backend {
    group = google_compute_region_network_endpoint_group.cloudrun_neg[count.index].id
  }
}

# NEG with Serverless Neg cloud run.
resource "google_compute_region_network_endpoint_group" "cloudrun_neg" {
  count                 = local.load_balancer_count
  name                  = "${var.load_balancer}-cloudrun-neg"
  project               = var.project_id
  network_endpoint_type = "SERVERLESS"
  region                = "us-central1"

  cloud_run {
    url_mask = "<service>.${var.load_balancer_domain}"
  }
}

# NEG with Internet Cloud run
# resource "google_compute_global_network_endpoint_group" "external_proxy" {
#   provider              = google-beta
#   project               = var.project_id
#   name                  = "${var.load_balancer}-network-endpoint"
#   network_endpoint_type = "INTERNET_FQDN_PORT"
#   default_port          = "443"
# }

# resource "google_compute_global_network_endpoint" "proxy" {
#   provider                      = google-beta
#   project                       = var.project_id
#   global_network_endpoint_group = google_compute_global_network_endpoint_group.external_proxy.id
#   # fqdn                          = trimprefix(data.google_cloud_run_service.run_service.status[0].url  , "https://")
#   fqdn                          = "run.app"
#   port                          = google_compute_global_network_endpoint_group.external_proxy.default_port
# }
# NEG with Internet Cloud run

# External IP Address for load balancer
resource "google_compute_global_address" "static-ip-address" {
  count   = local.load_balancer_count
  name    = "${var.load_balancer}-static-ip"
  project = var.project_id

  description = "The static ip address to use for the load balancer."
}

resource "google_compute_global_forwarding_rule" "https-rule" {
  count   = local.load_balancer_count
  name    = "${var.load_balancer}-https-proxy-rule"
  project = var.project_id

  target     = google_compute_target_https_proxy.https-proxy[count.index].id
  port_range = "443"

  ip_address = google_compute_global_address.static-ip-address[count.index].id
}

resource "google_compute_global_forwarding_rule" "static_http" {
  count   = local.load_balancer_count
  name    = "${var.load_balancer}-http-proxy-rule"
  project = var.project_id

  target     = google_compute_target_http_proxy.http-proxy[count.index].id
  port_range = "80"

  ip_address = google_compute_global_address.static-ip-address[count.index].id
}

# Random id for managed certificate.
resource "random_id" "certificate" {
  byte_length = 4
  prefix      = "${var.load_balancer}-load-balancer-certificate-"

  keepers = {
    domains = join(",", local.domains)
  }
}

#Managed SSL Certificates
resource "google_compute_managed_ssl_certificate" "load-balancer-certificate" {
  count   = local.load_balancer_count
  name    = random_id.certificate.hex
  project = var.project_id

  managed {
    # domains = [
    #   var.load_balancer_domain, "site-service.project.${var.load_balancer_domain}", "api-gateway.project.${var.load_balancer_domain}"
    # ]
    domains = concat([var.load_balancer_domain], local.domains)
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Managed certificate with wild card.
# resource "google_certificate_manager_certificate" "load-balancer-certificate" {
#   name        = "${var.load_balancer}-load-balancer-dns-cert2"
#   description = "The default cert"
#   project = var.project_id
#   #scope       = "EDGE_CACHE"
#   managed {
#     domains = local.domains

#     dns_authorizations = [for k, d in local.domains : google_certificate_manager_dns_authorization.load-balancer-certificate-instance[k].id]
#     # dns_authorizations = [
#     #   google_certificate_manager_dns_authorization.load-balancer-certificate-instance.id
#     # ]
#   }
# }

# resource "google_certificate_manager_dns_authorization" "load-balancer-certificate-instance" {
#   count = length(local.domains)
#   name        = "${var.load_balancer}-load-balancer-dns-auth-${count.index}"
#   description = "The default dnss"
#   domain      = local.domains[count.index]
# }
# Managed certificate with wild card.

# Load balancer
resource "google_compute_url_map" "load-balancer" {
  count   = local.load_balancer_count
  name    = "${var.load_balancer}-load-balancer"
  project = var.project_id

  default_service = google_compute_backend_bucket.load-balancer-bucket[count.index].id

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  dynamic "host_rule" {
    # for_each = { for o in var.load_balancer_cloud_run_services : o.name => o }
    for_each = var.load_balancer_cloud_run_services
    content {
      hosts        = ["${host_rule.value.name}.${var.load_balancer_domain}"]
      path_matcher = host_rule.value.name
    }
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.load-balancer-bucket[count.index].id
  }

  dynamic "path_matcher" {
    # for_each = { for o in var.load_balancer_cloud_run_services : o.name => o }
    for_each = var.load_balancer_cloud_run_services
    # iterator = "load-balancer-backend-service"
    content {
      name            = path_matcher.value.name
      default_service = google_compute_backend_service.load-balancer-run-service[count.index].id
    }
  }
}

resource "google_compute_target_https_proxy" "https-proxy" {
  count   = local.load_balancer_count
  name    = "${var.load_balancer}-https-proxy"
  project = var.project_id

  url_map          = google_compute_url_map.load-balancer[count.index].id
  ssl_certificates = [google_compute_managed_ssl_certificate.load-balancer-certificate[count.index].id]
  # ssl_certificates = [google_certificate_manager_certificate.load-balancer-certificate.id]
}

resource "google_compute_target_http_proxy" "http-proxy" {
  count   = local.load_balancer_count
  name    = "${var.load_balancer}-http-proxy"
  project = var.project_id

  url_map = google_compute_url_map.load-balancer[count.index].id
}

# Create the DNS entry.

