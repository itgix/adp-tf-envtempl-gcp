resource "google_compute_security_policy" "application" {
  count = local.cloud_armor_enabled ? 1 : 0

  description = "ADP application Cloud Armor policy for ${var.project_name}/${var.environment}"
  name        = "armor-${local.resource_prefix}"
  project     = var.gcp_project_id
  type        = "CLOUD_ARMOR"

  dynamic "rule" {
    for_each = var.cloud_armor_rules
    content {
      action      = try(rule.value.action, "deny(403)")
      description = try(rule.value.description, null)
      preview     = try(rule.value.preview, false)
      priority    = try(rule.value.priority, 1000 + rule.key)

      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = try(rule.value.src_ip_ranges, ["*"])
        }
      }
    }
  }

  rule {
    action   = local.cloud_armor_default_action
    priority = 2147483647

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }

  depends_on = [module.project_services]
}
