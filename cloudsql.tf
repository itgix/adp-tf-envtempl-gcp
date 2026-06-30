resource "random_password" "cloudsql_admin" {
  count = local.create_cloudsql_postgres ? 1 : 0

  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "cloudsql_extra" {
  count = local.create_cloudsql_postgres && var.cloudsql_create_extra_user && try(var.cloudsql_extra_credentials.password, null) == null ? 1 : 0

  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

locals {
  cloudsql_instance_name = var.cloudsql_instance_name != "" ? var.cloudsql_instance_name : "sql-${local.resource_prefix}"
  cloudsql_extra_password = local.create_cloudsql_postgres && var.cloudsql_create_extra_user ? (
    try(var.cloudsql_extra_credentials.password, null) != null ? var.cloudsql_extra_credentials.password : random_password.cloudsql_extra[0].result
  ) : null
}

resource "google_sql_database_instance" "postgres" {
  count = local.create_cloudsql_postgres ? 1 : 0

  database_version    = var.cloudsql_database_version
  deletion_protection = var.cloudsql_deletion_protection
  name                = local.cloudsql_instance_name
  project             = var.gcp_project_id
  region              = var.region

  settings {
    availability_type = var.cloudsql_availability_type
    disk_autoresize   = true
    disk_size         = var.cloudsql_disk_size_gb
    disk_type         = var.cloudsql_disk_type
    tier              = var.cloudsql_tier
    user_labels       = local.common_labels

    backup_configuration {
      enabled                        = var.cloudsql_backup_enabled
      point_in_time_recovery_enabled = var.cloudsql_point_in_time_recovery_enabled
      start_time                     = var.cloudsql_backup_start_time
    }

    ip_configuration {
      ipv4_enabled    = var.cloudsql_public_ip_enabled
      private_network = local.private_services_enabled ? local.vpc_network_id : null

      dynamic "authorized_networks" {
        for_each = var.cloudsql_public_ip_enabled ? var.cloudsql_authorized_networks : []
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
    }

    dynamic "database_flags" {
      for_each = var.cloudsql_database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }
  }

  depends_on = [
    google_project_service.required,
    google_service_networking_connection.private_services,
  ]
}

resource "google_sql_database" "main" {
  count = local.create_cloudsql_postgres && var.cloudsql_database_name != "" ? 1 : 0

  instance = google_sql_database_instance.postgres[0].name
  name     = var.cloudsql_database_name
  project  = var.gcp_project_id
}

resource "google_sql_user" "admin" {
  count = local.create_cloudsql_postgres ? 1 : 0

  instance = google_sql_database_instance.postgres[0].name
  name     = var.cloudsql_default_username
  password = random_password.cloudsql_admin[0].result
  project  = var.gcp_project_id
}

resource "google_sql_database" "extra" {
  count = local.create_cloudsql_postgres && var.cloudsql_create_extra_user ? 1 : 0

  instance = google_sql_database_instance.postgres[0].name
  name     = var.cloudsql_extra_credentials.database
  project  = var.gcp_project_id
}

resource "google_sql_user" "extra" {
  count = local.create_cloudsql_postgres && var.cloudsql_create_extra_user ? 1 : 0

  instance = google_sql_database_instance.postgres[0].name
  name     = var.cloudsql_extra_credentials.username
  password = local.cloudsql_extra_password
  project  = var.gcp_project_id
}

resource "google_secret_manager_secret" "cloudsql_admin" {
  count = local.create_cloudsql_postgres ? 1 : 0

  labels    = local.common_labels
  project   = var.gcp_project_id
  secret_id = "${local.secret_prefix}cloudsql-${var.cloudsql_default_username}-password"

  replication {
    auto {}
  }

  depends_on = [google_project_service.required]
}

resource "google_secret_manager_secret_version" "cloudsql_admin" {
  count = local.create_cloudsql_postgres ? 1 : 0

  secret      = google_secret_manager_secret.cloudsql_admin[0].id
  secret_data = random_password.cloudsql_admin[0].result
}

resource "google_secret_manager_secret" "cloudsql_extra" {
  count = local.create_cloudsql_postgres && var.cloudsql_create_extra_user ? 1 : 0

  labels    = local.common_labels
  project   = var.gcp_project_id
  secret_id = "${local.secret_prefix}cloudsql-${var.cloudsql_extra_credentials.username}-password"

  replication {
    auto {}
  }

  depends_on = [google_project_service.required]
}

resource "google_secret_manager_secret_version" "cloudsql_extra" {
  count = local.create_cloudsql_postgres && var.cloudsql_create_extra_user ? 1 : 0

  secret      = google_secret_manager_secret.cloudsql_extra[0].id
  secret_data = local.cloudsql_extra_password
}

