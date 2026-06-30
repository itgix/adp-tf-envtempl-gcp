resource "google_dns_managed_zone" "this" {
  count = var.create_dns_managed_zone ? 1 : 0

  description = var.dns_zone_description
  dns_name    = var.dns_zone_dns_name != "" ? var.dns_zone_dns_name : "${trim(var.dns_main_domain, ".")}."
  labels      = local.common_labels
  name        = var.dns_managed_zone
  project     = var.gcp_project_id
  visibility  = var.dns_zone_visibility

  depends_on = [google_project_service.required]
}

data "google_dns_managed_zone" "existing" {
  count = var.lookup_dns_managed_zone && !var.create_dns_managed_zone && var.dns_managed_zone != "" ? 1 : 0

  name    = var.dns_managed_zone
  project = var.gcp_project_id
}

