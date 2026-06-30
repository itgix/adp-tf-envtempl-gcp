module "dns_managed_zone" {
  count = var.dns_managed_zone != "" && (var.create_dns_managed_zone || var.lookup_dns_managed_zone) ? 1 : 0

  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/dns?ref=v54.3.0&depth=1"

  project_id  = var.gcp_project_id
  name        = var.dns_managed_zone
  description = var.dns_zone_description
  labels      = local.common_labels
  zone_config = local.dns_zone_config

  depends_on = [module.project_services]
}
