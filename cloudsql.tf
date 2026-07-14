module "cloudsql_postgres" {
  count = local.create_cloudsql_postgres ? 1 : 0

  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/cloudsql-instance?ref=v54.3.0&depth=1"

  project_id                    = var.gcp_project_id
  name                          = local.cloudsql_instance_name
  region                        = var.region
  database_version              = var.cloudsql_database_version
  tier                          = var.cloudsql_tier
  availability_type             = var.cloudsql_availability_type
  disk_size                     = var.cloudsql_disk_size_gb
  disk_type                     = var.cloudsql_disk_type
  labels                        = local.common_labels
  terraform_deletion_protection = var.cloudsql_deletion_protection
  gcp_deletion_protection       = var.cloudsql_deletion_protection
  backup_configuration = {
    enabled                        = var.cloudsql_backup_enabled
    point_in_time_recovery_enabled = var.cloudsql_point_in_time_recovery_enabled
    start_time                     = var.cloudsql_backup_start_time
  }
  flags     = local.cloudsql_database_flags_map
  databases = length(local.cloudsql_databases) > 0 ? local.cloudsql_databases : null
  users     = local.cloudsql_users
  network_config = {
    authorized_networks = var.cloudsql_public_ip_enabled ? local.cloudsql_authorized_networks_map : {}
    connectivity = {
      public_ipv4                      = var.cloudsql_public_ip_enabled
      enable_private_path_for_services = true
      psa_config = local.private_services_enabled ? {
        private_network = local.vpc_network_self_link
      } : null
    }
  }

  depends_on = [
    module.project_services,
    module.vpc,
  ]
}
