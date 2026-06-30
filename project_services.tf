resource "google_project_service" "required" {
  for_each = var.enable_project_services ? local.required_project_services : toset([])

  project            = var.gcp_project_id
  service            = each.key
  disable_on_destroy = var.disable_services_on_destroy
}

