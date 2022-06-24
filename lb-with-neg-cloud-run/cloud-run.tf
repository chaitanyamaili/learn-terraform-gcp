# resource "google_cloud_run_service" "run_service" {
#   name     = "neg-helloworld"
#   project  = var.project_id2
#   location = "us-central1"

#   template {
#     spec {
#       containers {
#         image = "gcr.io/decoupled-hw-mr-demo/helloworld"
#       }
#     }
#   }

#   traffic {
#     percent         = 100
#     latest_revision = true
#   }
# }

# data "google_cloud_run_service" "run_service" {
#   for_each = var.cloud_run_service
#     name     = cloud_run_service.value["service_name"]
#     project  = cloud_run_service.value["project"]
#     location = cloud_run_service.value["location"]
# }

data "google_cloud_run_service" "run_service1" {
  name     = "helloworld"
  project  = var.project_id2
  location = "us-central1"
}

data "google_cloud_run_service" "run_service2" {
  name     = "helloworld2"
  project  = var.project_id2
  location = "asia-south1"
}

# data "google_iam_policy" "noauth" {
#   binding {
#     role = "roles/run.invoker"
#     members = [
#       "allUsers",
#     ]
#   }
# }

# resource "google_cloud_run_service_iam_policy" "noauth" {
#   location    = google_cloud_run_service.run_service.location
#   project     = google_cloud_run_service.run_service.project
#   service     = google_cloud_run_service.run_service.name

#   policy_data = data.google_iam_policy.noauth.policy_data
# }
