resource "random_password" "custom_secrets" {
  for_each = local.generated_custom_secrets

  length           = coalesce(try(each.value.length, null), 32)
  special          = coalesce(try(each.value.special, null), true)
  override_special = coalesce(try(each.value.override_special, null), "!#$%&*()-_=+[]{}<>:?")
  keepers          = merge(try(var.custom_secret_keepers[each.key], {}), try(each.value.keepers, {}))
}

module "secret_manager" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/secret-manager?ref=v54.3.0&depth=1"

  project_id = var.gcp_project_id
  secrets    = local.secret_manager_secrets

  depends_on = [module.project_services]
}
