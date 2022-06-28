output "second_project" {
  description = "Second project."
  value       = var.load_balancer_cloud_run_services[0].project
}

output "second_location" {
  description = "Second project."
  value       = var.load_balancer_cloud_run_services[0].location
}

output "service_url1" {
  description = "Cloud run url1 "
  value       = data.google_cloud_run_service.run_service[0].status[0].url
}

output "service_fqdn1" {
  description = "Cloud fqdn url1"
  value       = trimprefix(data.google_cloud_run_service.run_service[0].status[0].url, "https://")
}

output "service_url2" {
  description = "Cloud run url2"
  value       = data.google_cloud_run_service.run_service[1].status[0].url
}

output "service_fqdn2" {
  description = "Cloud fqdn url2"
  value       = trimprefix(data.google_cloud_run_service.run_service[1].status[0].url, "https://")
}
