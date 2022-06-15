terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.23.0"
    }
  }
}

provider "google" {
  credentials = file("sa-cm-terraform.json")
  project     = "parallel-dynamic-runtime-tf"
  region      = "us-central1"
  zone        = "us-central1-c"
}

resource "random_id" "instance_id" {
  byte_length = 8
}

# resource "google_compute_network" "vpc_network" {
#   name = "default"
# }

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance-${random_id.instance_id.hex}"
  machine_type = "f1-micro"
  zone         = "us-central1-c"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "vpc-1-pdk"
    subnetwork = "vpc-1-us-central"
    access_config {}
  }

  // Apply the firewall rule to allow external IPs to access this instance
  tags = ["web", "test"]
}
