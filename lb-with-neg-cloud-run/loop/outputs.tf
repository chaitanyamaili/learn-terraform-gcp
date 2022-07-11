# output "second_project" {
#   description = "Second project."
#   value       = var.load_balancer_cloud_run_services[0].project
# }

# output "second_location" {
#   description = "Second project."
#   value       = var.load_balancer_cloud_run_services[0].location
# }

# output "service_url1" {
#   description = "Cloud run url1 "
#   value       = data.google_cloud_run_service.run_service[0].status[0].url
# }

# output "service_fqdn1" {
#   description = "Cloud fqdn url1"
#   value       = trimprefix(data.google_cloud_run_service.run_service[0].status[0].url, "https://")
# }

# output "service_url2" {
#   description = "Cloud run url2"
#   value       = data.google_cloud_run_service.run_service[1].status[0].url
# }

# output "service_fqdn2" {
#   description = "Cloud fqdn url2"
#   value       = trimprefix(data.google_cloud_run_service.run_service[1].status[0].url, "https://")
# }

output "local_domain" {
  description = "Local domains as list"
  value       = local.domains
}

output "lb_ip_address" {
  description = "Load balancer IP address."
  value       = length(google_compute_global_address.static-ip-address) > 0 ? google_compute_global_address.static-ip-address[0].address : ""
}

output "load_balancer_count" {
  description = "Load balancer flag."
  value       = local.load_balancer_count
}
