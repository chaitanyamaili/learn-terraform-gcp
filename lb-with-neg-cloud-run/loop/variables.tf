variable "project_id" {
  description = "Project Id."
  type        = string
}

variable "project_id2" {
  description = "Project Id."
  type        = string
}

variable "prefix" {
  description = "Prefix used to generate project shared name."
  type        = string
}

variable "location" {
  description = "Location used to generate resource."
  type        = string
}

variable "load_balancer_storage" {
  description = "GCS Bucket name for load balancer default backend"
  type        = string
}

variable "load_balancer" {
  description = "Name for the load balancer."
  type        = string
}

variable "load_balancer_domain" {
  description = "Domain name for the load balancer."
  type        = string
}

variable "load_balancer_cloud_run_services" {
  description = "List of all cloud run services."
  type = list(object({
    name     = string,
    project  = string,
    location = string
  }))
}
