resource "google_firestore_database" "this" {
  count = local.create_firestore ? 1 : 0

  app_engine_integration_mode = "DISABLED"
  delete_protection_state     = var.firestore_delete_protection ? "DELETE_PROTECTION_ENABLED" : "DELETE_PROTECTION_DISABLED"
  deletion_policy             = var.firestore_deletion_policy
  location_id                 = var.firestore_location != "" ? var.firestore_location : var.region
  name                        = var.firestore_database_id
  project                     = var.gcp_project_id
  type                        = "FIRESTORE_NATIVE"

  depends_on = [google_project_service.required]
}

