variable "project" {
  type = string
}

variable "load_balancer_name" { 
  type = string
  default = "cm-sa-website-062022-v3"
}

variable "bucket_name" {
  type = string
  default = "cm-sa-http-lb-062022-v3"
}
