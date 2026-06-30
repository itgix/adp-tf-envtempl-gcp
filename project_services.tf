module "project_services" {
  count = var.enable_project_services ? 1 : 0

  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/project?ref=v54.3.0&depth=1"

  name = var.gcp_project_id
  project_reuse = {
    use_data_source = true
  }
  labels   = local.common_labels
  services = tolist(local.required_project_services)
  service_config = {
    disable_dependent_services = false
    disable_on_destroy         = var.disable_services_on_destroy
  }
}
