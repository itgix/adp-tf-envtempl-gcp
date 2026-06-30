resource "google_artifact_registry_repository" "repositories" {
  for_each = local.effective_artifact_registry_repositories

  description   = try(each.value.description, "ADP Artifact Registry repository")
  format        = upper(try(each.value.format, "DOCKER"))
  labels        = merge(local.common_labels, try(each.value.labels, {}))
  location      = local.artifact_registry_location
  project       = var.gcp_project_id
  repository_id = try(each.value.repository_id, each.key)

  dynamic "docker_config" {
    for_each = upper(try(each.value.format, "DOCKER")) == "DOCKER" ? [1] : []
    content {
      immutable_tags = try(each.value.immutable_tags, var.artifact_registry_immutable_tags)
    }
  }

  depends_on = [google_project_service.required]
}

resource "google_artifact_registry_repository_iam_member" "readers" {
  for_each = {
    for item in flatten([
      for repo_key, repo in google_artifact_registry_repository.repositories : [
        for member in var.artifact_registry_reader_members : {
          key        = "${repo_key}:${member}"
          location   = repo.location
          member     = member
          repository = repo.repository_id
        }
      ]
    ]) : item.key => item
  }

  location   = each.value.location
  member     = each.value.member
  project    = var.gcp_project_id
  repository = each.value.repository
  role       = "roles/artifactregistry.reader"
}

resource "google_artifact_registry_repository_iam_member" "writers" {
  for_each = {
    for item in flatten([
      for repo_key, repo in google_artifact_registry_repository.repositories : [
        for member in var.artifact_registry_writer_members : {
          key        = "${repo_key}:${member}"
          location   = repo.location
          member     = member
          repository = repo.repository_id
        }
      ]
    ]) : item.key => item
  }

  location   = each.value.location
  member     = each.value.member
  project    = var.gcp_project_id
  repository = each.value.repository
  role       = "roles/artifactregistry.writer"
}

