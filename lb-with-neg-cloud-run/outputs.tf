output "service_url" {
  description = "Cloud run url"
  value       = data.google_cloud_run_service.run_service.status[0].url
}

output "service_fqdn" {
  description = "Cloud run url"
  value       = trimprefix(data.google_cloud_run_service.run_service.status[0].url, "https://")
}
