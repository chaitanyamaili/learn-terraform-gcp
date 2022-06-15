variable "project_id" {
  description   = "Google project ID."
  type          = string
}

variable "storage_class" {
  description   = "The Storage Class of the new bucket."
  type          = string
  default       = "STANDARD"
}

variable "versioning" {
  description   = "While set to true, versioning is fully enabled for this bucket."
  type          = bool
  default       = false
}

variable "bucket_name" {
  description   = "GCS bucket name, value should be unique."
  type          = string
}

variable "region" {
  description   = "Google cloud region."
  type          = string
  default       = "us-east1"
}
