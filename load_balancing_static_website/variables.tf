variable "project" {
  description = "Google project ID."
  type        = string
}

variable "environment" {
  description = "Environoment name."
  type        = string
  default     = "dev"
}

variable "prefix" {
  description = "Prefix name."
  type        = string
  default     = "cm-sa"
}

variable "bucket_location" {
  description = "Google cloud storage region."
  type        = string
  default     = "US"
}

variable "bucket_name" {
  description = "Name of the cloud storage bucket as backend."
  type        = string
}

variable "lb_name" {
  description = "Name of Load balancer."
  type        = string
}
