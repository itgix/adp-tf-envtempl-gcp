resource "random_password" "custom_secrets" {
  for_each = local.generated_custom_secrets

  length           = coalesce(try(each.value.length, null), 32)
  special          = coalesce(try(each.value.special, null), true)
  override_special = coalesce(try(each.value.override_special, null), "!#$%&*()-_=+[]{}<>:?")
  keepers          = merge(try(var.custom_secret_keepers[each.key], {}), try(each.value.keepers, {}))
}

resource "google_secret_manager_secret" "custom" {
  for_each = local.custom_secrets_by_name

  labels    = local.common_labels
  project   = var.gcp_project_id
  secret_id = "${local.secret_prefix}${each.value.secret_name}"

  replication {
    auto {}
  }

  depends_on = [google_project_service.required]
}

resource "google_secret_manager_secret_version" "custom" {
  for_each = local.custom_secret_payloads

  secret      = google_secret_manager_secret.custom[each.key].id
  secret_data = each.value
}

