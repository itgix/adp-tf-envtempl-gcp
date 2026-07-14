module "artifact_registry" {
  for_each = local.effective_artifact_registry_repositories

  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/artifact-registry?ref=v54.3.0&depth=1"

  project_id  = var.gcp_project_id
  location    = local.artifact_registry_location
  name        = try(each.value.repository_id, each.key)
  description = try(each.value.description, "ADP Artifact Registry repository")
  labels      = merge(local.common_labels, try(each.value.labels, {}))
  format = {
    apt = upper(try(each.value.format, "DOCKER")) == "APT" ? {
      standard = true
    } : null
    docker = upper(try(each.value.format, "DOCKER")) == "DOCKER" ? {
      standard = {
        immutable_tags = try(each.value.immutable_tags, var.artifact_registry_immutable_tags)
      }
    } : null
    generic = upper(try(each.value.format, "DOCKER")) == "GENERIC" ? {
      standard = true
    } : null
    go = upper(try(each.value.format, "DOCKER")) == "GO" ? {
      standard = true
    } : null
    googet = upper(try(each.value.format, "DOCKER")) == "GOOGET" ? {
      standard = true
    } : null
    kfp = upper(try(each.value.format, "DOCKER")) == "KFP" ? {
      standard = true
    } : null
    maven = upper(try(each.value.format, "DOCKER")) == "MAVEN" ? {
      standard = {}
    } : null
    npm = upper(try(each.value.format, "DOCKER")) == "NPM" ? {
      standard = true
    } : null
    python = upper(try(each.value.format, "DOCKER")) == "PYTHON" ? {
      standard = true
    } : null
    yum = upper(try(each.value.format, "DOCKER")) == "YUM" ? {
      standard = true
    } : null
  }
  iam = merge(
    length(var.artifact_registry_reader_members) > 0 ? {
      "roles/artifactregistry.reader" = var.artifact_registry_reader_members
    } : {},
    length(var.artifact_registry_writer_members) > 0 ? {
      "roles/artifactregistry.writer" = var.artifact_registry_writer_members
    } : {}
  )

  depends_on = [module.project_services]
}
