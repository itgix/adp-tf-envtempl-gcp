module "gcs_buckets" {
  for_each = local.effective_bucket_configuration

  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/gcs?ref=v54.3.0&depth=1"

  project_id                  = var.gcp_project_id
  name                        = lower(replace(coalesce(try(each.value.bucket_name, null), "${var.gcp_project_id}-${local.resource_prefix}-${each.value.bucket_name_suffix}"), "/[^a-z0-9._-]/", "-"))
  location                    = coalesce(try(each.value.location, null), var.region)
  storage_class               = coalesce(try(each.value.storage_class, null), "STANDARD")
  labels                      = merge(local.common_labels, try(each.value.labels, {}))
  force_destroy               = coalesce(try(each.value.force_destroy, null), var.gcs_force_destroy)
  public_access_prevention    = coalesce(try(each.value.public_access_prevention, null), "enforced")
  uniform_bucket_level_access = coalesce(try(each.value.uniform_bucket_level_access, null), true)
  versioning                  = coalesce(try(each.value.versioning, null), try(each.value.versioning_enabled, null), true)
  cors = length(try(each.value.cors_configuration, [])) > 0 ? {
    origin          = each.value.cors_configuration[0].allowed_origins
    method          = each.value.cors_configuration[0].allowed_methods
    response_header = each.value.cors_configuration[0].expose_headers
    max_age_seconds = each.value.cors_configuration[0].max_age_seconds
  } : null
  lifecycle_rules = try(each.value.lifecycle_age_days, null) != null ? {
    delete-old-objects = {
      action = {
        type = "Delete"
      }
      condition = {
        age = each.value.lifecycle_age_days
      }
    }
  } : {}

  depends_on = [module.project_services]
}
