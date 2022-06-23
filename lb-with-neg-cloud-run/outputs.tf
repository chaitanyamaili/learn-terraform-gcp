output "service_url" {
  description = "Cloud run url"
  value       = data.google_cloud_run_service.run_service.status[0].url
}

output "service_fqdn" {
  description = "Cloud run url"
  value       = trimprefix(data.google_cloud_run_service.run_service.status[0].url, "https://")
}

# output "record_name_to_insert" {
#  value = google_certificate_manager_dns_authorization.load-balancer-certificate-instance.dns_resource_record.0.name
# }

# output "record_type_to_insert" {
#  value = google_certificate_manager_dns_authorization.load-balancer-certificate-instance.dns_resource_record.0.type
# }

# output "record_data_to_insert" {
#  value = google_certificate_manager_dns_authorization.load-balancer-certificate-instance.dns_resource_record.0.data
# } 
