resource "google_service_account" "workload_identity" {
  for_each = local.workload_identity_bindings_normalized

  account_id   = trim(substr(trim(replace(lower("${each.key}-${local.resource_prefix}"), "/[^a-z0-9-]/", "-"), "-"), 0, 30), "-")
  description  = each.value.description
  display_name = "ADP ${each.key}"
  project      = var.gcp_project_id

  depends_on = [google_project_service.required]
}

resource "google_project_iam_member" "workload_identity_roles" {
  for_each = {
    for binding in local.workload_identity_role_bindings : binding.key => binding
  }

  project = var.gcp_project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.workload_identity[each.value.name].email}"
}

resource "google_service_account_iam_member" "workload_identity_user" {
  for_each = local.workload_identity_bindings_normalized

  service_account_id = google_service_account.workload_identity[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = local.workload_identity_members[each.key]
}
