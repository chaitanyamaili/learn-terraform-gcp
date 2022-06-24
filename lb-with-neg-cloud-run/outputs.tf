output "service_url1" {
  description = "Cloud run url1"
  value       = data.google_cloud_run_service.run_service1.status[0].url
}

output "service_fqdn1" {
  description = "Cloud fqdn url1"
  value       = trimprefix(data.google_cloud_run_service.run_service1.status[0].url, "https://")
}

output "service_url2" {
  description = "Cloud run url2"
  value       = data.google_cloud_run_service.run_service2.status[0].url
}

output "service_fqdn2" {
  description = "Cloud fqdn url2"
  value       = trimprefix(data.google_cloud_run_service.run_service2.status[0].url, "https://")
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
