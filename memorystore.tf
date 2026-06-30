resource "google_redis_instance" "redis" {
  count = local.create_memorystore_redis ? 1 : 0

  alternative_location_id = var.memorystore_alternative_location_id != "" ? var.memorystore_alternative_location_id : null
  auth_enabled            = var.memorystore_auth_enabled
  authorized_network      = local.vpc_network_id
  connect_mode            = var.memorystore_connect_mode
  display_name            = "ADP Redis ${var.project_name}/${var.environment}"
  labels                  = local.common_labels
  location_id             = var.memorystore_location_id != "" ? var.memorystore_location_id : null
  memory_size_gb          = var.memorystore_memory_size_gb
  name                    = var.memorystore_name != "" ? var.memorystore_name : "redis-${local.resource_prefix}"
  project                 = var.gcp_project_id
  redis_version           = var.memorystore_redis_version
  region                  = var.region
  tier                    = var.memorystore_tier

  depends_on = [
    google_project_service.required,
    google_service_networking_connection.private_services,
  ]
}

