module "dns-public-zone" {
  source     = "terraform-google-modules/cloud-dns/google"
  version    = "3.0.0"
  project_id = var.project_id
  type       = "public"
  name       = "${replace(var.load_balancer_domain, ".", "-")}-zone"
  domain     = "${var.load_balancer_domain}."

  recordsets = [
    for sub_domain in var.load_balancer_cloud_run_services :
    {
      name = sub_domain.name
      type = "A"
      ttl  = 300
      records = [
        google_compute_global_address.static-ip-address.address,
      ]
    }
  ]
}
