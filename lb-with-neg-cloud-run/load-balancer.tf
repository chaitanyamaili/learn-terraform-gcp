# Use Google-provided module to define a bucket
provider "google" {
  project = var.project_id
  # version = "4.26.0"
}

# Use Google-provided module to define a bucket
provider "google-beta" {
  project = var.project_id
  # version = "4.26.0"
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

# Backend network end point group1 (NEG)
resource "google_compute_backend_service" "load-balancer-run-service" {
  count                           = length(var.load_balancer_cloud_run_services)
  name                            = "${var.load_balancer}-load-balancer-backend-service${count.index}"
  enable_cdn                      = false
  timeout_sec                     = 10
  connection_draining_timeout_sec = 10
  protocol                        = "HTTPS"

  custom_request_headers = ["Host:${trimprefix(data.google_cloud_run_service.run_service[count.index].status[0].url, "https://")}"]

  backend {
    group = google_compute_global_network_endpoint_group.external_proxy.id
  }
}

# NEG with Internet Cloud run
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
  # fqdn                          = trimprefix(data.google_cloud_run_service.run_service.status[0].url  , "https://")
  fqdn = "run.app"
  port = google_compute_global_network_endpoint_group.external_proxy.default_port
}
# NEG with Internet Cloud run

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

#Managed SSL Certificates
resource "google_compute_managed_ssl_certificate" "load-balancer-certificate" {
  name    = "${var.load_balancer}-load-balancer-certificate"
  project = var.project_id

  managed {
    domains = [
      var.load_balancer_domain, "site-service.project.${var.load_balancer_domain}", "api-gateway.project.${var.load_balancer_domain}"
    ]
  }
}

# resource "google_compute_managed_ssl_certificate" "load-balancer-certificate2" {
#   name    = "${var.load_balancer}-load-balancer-certificate2"
#   project = var.project_id

#   managed {
#     domains = [
#       var.load_balancer_domain, "site-service.project.${var.load_balancer_domain}", "api-gateway.project.${var.load_balancer_domain}"
#     ]
#   }
# }

# resource "google_certificate_manager_certificate" "load-balancer-certificate" {
#   name        = "${var.load_balancer}-load-balancer-dns-cert2"
#   description = "The default cert"
#   project = var.project_id
#   #scope       = "EDGE_CACHE"
#   managed {
#     domains = [
#       var.load_balancer_domain
#     ]
#     dns_authorizations = [
#       google_certificate_manager_dns_authorization.load-balancer-certificate-instance.id
#       # google_certificate_manager_dns_authorization.load-balancer-certificate-instance2.id
#     ]
#   }
# }

# resource "google_certificate_manager_dns_authorization" "load-balancer-certificate-instance" {
#   name        = "${var.load_balancer}-load-balancer-dns-auth"
#   description = "The default dnss"
#   domain      = var.load_balancer_domain
# }
# resource "google_certificate_manager_dns_authorization" "load-balancer-certificate-instance2" {
#   name        = "${var.load_balancer}-load-balancer-dns-auth2"
#   description = "The default dnss"
#   domain      = "site-service.project.${var.load_balancer_domain}"
# }

# Load balancer
resource "google_compute_url_map" "load-balancer" {
  name    = "${var.load_balancer}-load-balancer"
  project = var.project_id

  default_service = google_compute_backend_bucket.load-balancer-bucket.id

  # host_rule {
  #   hosts        = ["/*"]
  #   path_matcher = "allpaths"
  # }

  # path_matcher {
  #   name            = "allpaths"
  #   default_service = google_compute_backend_bucket.load-balancer-bucket.id
  # }

  dynamic "host_rule" {
    # for_each = { for o in var.load_balancer_cloud_run_services : o.name => o }
    for_each = var.load_balancer_cloud_run_services
    content {
      hosts        = ["${host_rule.value.alias}.project.${var.load_balancer_domain}"]
      path_matcher = host_rule.value.alias
    }
  }

  dynamic "path_matcher" {
    # for_each = { for o in var.load_balancer_cloud_run_services : o.name => o }
    for_each = var.load_balancer_cloud_run_services
    # iterator = "load-balancer-backend-service"
    content {
      name            = path_matcher.value.alias
      default_service = google_compute_backend_service.load-balancer-run-service[path_matcher.key].id
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
