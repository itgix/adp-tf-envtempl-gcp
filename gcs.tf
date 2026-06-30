resource "google_storage_bucket" "buckets" {
  for_each = local.effective_bucket_configuration

  force_destroy               = coalesce(try(each.value.force_destroy, null), var.gcs_force_destroy)
  labels                      = merge(local.common_labels, try(each.value.labels, {}))
  location                    = coalesce(try(each.value.location, null), var.region)
  name                        = lower(replace(coalesce(try(each.value.bucket_name, null), "${var.gcp_project_id}-${local.resource_prefix}-${each.value.bucket_name_suffix}"), "/[^a-z0-9._-]/", "-"))
  project                     = var.gcp_project_id
  public_access_prevention    = coalesce(try(each.value.public_access_prevention, null), "enforced")
  storage_class               = coalesce(try(each.value.storage_class, null), "STANDARD")
  uniform_bucket_level_access = coalesce(try(each.value.uniform_bucket_level_access, null), true)

  versioning {
    enabled = coalesce(try(each.value.versioning, null), try(each.value.versioning_enabled, null), true)
  }

  dynamic "cors" {
    for_each = try(each.value.cors_configuration, [])
    content {
      max_age_seconds = cors.value.max_age_seconds
      method          = cors.value.allowed_methods
      origin          = cors.value.allowed_origins
      response_header = cors.value.expose_headers
    }
  }

  dynamic "lifecycle_rule" {
    for_each = try(each.value.lifecycle_age_days, null) != null ? [each.value.lifecycle_age_days] : []
    content {
      action {
        type = "Delete"
      }

      condition {
        age = lifecycle_rule.value
      }
    }
  }

  depends_on = [google_project_service.required]
}

