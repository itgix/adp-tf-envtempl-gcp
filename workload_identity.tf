module "workload_identity_service_accounts" {
  for_each = local.workload_identity_bindings_normalized

  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/iam-service-account?ref=v54.3.0&depth=1"

  project_id   = var.gcp_project_id
  name         = trim(substr(trim(replace(lower("${each.key}-${local.resource_prefix}"), "/[^a-z0-9-]/", "-"), "-"), 0, 30), "-")
  description  = each.value.description
  display_name = "ADP ${each.key}"

  depends_on = [module.project_services]
}

resource "google_project_iam_member" "workload_identity_roles" {
  for_each = {
    for binding in local.workload_identity_role_bindings : binding.key => binding
  }

  project = var.gcp_project_id
  role    = each.value.role
  member  = "serviceAccount:${module.workload_identity_service_accounts[each.value.name].email}"
}

resource "google_service_account_iam_member" "workload_identity_user" {
  for_each = local.workload_identity_bindings_normalized

  service_account_id = module.workload_identity_service_accounts[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = local.workload_identity_members[each.key]

  depends_on = [
    module.gke_standard,
    module.gke_autopilot,
    module.gke_nodepool_primary,
  ]
}
