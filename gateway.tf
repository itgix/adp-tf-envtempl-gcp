locals {
  shared_gateway_domain = trim(var.dns_main_domain, ".")
  shared_gateway_name   = "${local.resource_prefix}-gateway"
}

data "google_dns_managed_zone" "shared_gateway" {
  count = var.gcp_shared_gateway_enabled ? 1 : 0

  project = var.gcp_project_id
  name    = var.dns_managed_zone

  depends_on = [module.dns_managed_zone, module.project_services]
}

resource "google_compute_global_address" "shared_gateway" {
  count = var.gcp_shared_gateway_enabled ? 1 : 0

  project      = var.gcp_project_id
  name         = local.shared_gateway_name
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
  labels       = local.common_labels

  lifecycle {
    precondition {
      condition = (
        data.google_dns_managed_zone.shared_gateway[0].visibility == "public" &&
        ("${local.shared_gateway_domain}." == data.google_dns_managed_zone.shared_gateway[0].dns_name ||
        endswith("${local.shared_gateway_domain}.", ".${data.google_dns_managed_zone.shared_gateway[0].dns_name}"))
      )
      error_message = "The shared Gateway domain must be inside the selected public Cloud DNS zone."
    }
  }

  depends_on = [module.project_services]
}

resource "google_certificate_manager_dns_authorization" "shared_gateway" {
  count = var.gcp_shared_gateway_enabled ? 1 : 0

  project = var.gcp_project_id
  name    = local.shared_gateway_name
  domain  = local.shared_gateway_domain
  type    = "PER_PROJECT_RECORD"
  labels  = local.common_labels

  depends_on = [module.project_services]
}

resource "google_dns_record_set" "shared_gateway_authorization" {
  count = var.gcp_shared_gateway_enabled ? 1 : 0

  project      = var.gcp_project_id
  managed_zone = data.google_dns_managed_zone.shared_gateway[0].name
  name         = google_certificate_manager_dns_authorization.shared_gateway[0].dns_resource_record[0].name
  type         = google_certificate_manager_dns_authorization.shared_gateway[0].dns_resource_record[0].type
  ttl          = 300
  rrdatas      = [google_certificate_manager_dns_authorization.shared_gateway[0].dns_resource_record[0].data]
}

resource "google_certificate_manager_certificate" "shared_gateway" {
  count = var.gcp_shared_gateway_enabled ? 1 : 0

  project = var.gcp_project_id
  name    = local.shared_gateway_name
  labels  = local.common_labels
  managed {
    domains            = ["*.${local.shared_gateway_domain}"]
    dns_authorizations = [google_certificate_manager_dns_authorization.shared_gateway[0].id]
  }

  depends_on = [google_dns_record_set.shared_gateway_authorization]
}

resource "google_certificate_manager_certificate_map" "shared_gateway" {
  count = var.gcp_shared_gateway_enabled ? 1 : 0

  project = var.gcp_project_id
  name    = local.shared_gateway_name
  labels  = local.common_labels

  depends_on = [module.project_services]
}

resource "google_certificate_manager_certificate_map_entry" "shared_gateway" {
  count = var.gcp_shared_gateway_enabled ? 1 : 0

  project      = var.gcp_project_id
  name         = local.shared_gateway_name
  map          = google_certificate_manager_certificate_map.shared_gateway[0].name
  certificates = [google_certificate_manager_certificate.shared_gateway[0].id]
  hostname     = "*.${local.shared_gateway_domain}"
}

resource "google_dns_record_set" "shared_gateway" {
  count = var.gcp_shared_gateway_enabled ? 1 : 0

  project      = var.gcp_project_id
  managed_zone = data.google_dns_managed_zone.shared_gateway[0].name
  name         = "*.${local.shared_gateway_domain}."
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.shared_gateway[0].address]
}
