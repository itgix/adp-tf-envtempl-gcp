module "firestore" {
  count = local.create_firestore ? 1 : 0

  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/firestore?ref=v54.3.0&depth=1"

  project_id = var.gcp_project_id
  database = {
    app_engine_integration_mode = "DISABLED"
    deletion_policy             = var.firestore_deletion_policy
    delete_protection_state     = var.firestore_delete_protection ? "DELETE_PROTECTION_ENABLED" : "DELETE_PROTECTION_DISABLED"
    location_id                 = var.firestore_location != "" ? var.firestore_location : var.region
    name                        = var.firestore_database_id
    type                        = "FIRESTORE_NATIVE"
  }

  depends_on = [module.project_services]
}
