output "region_short" {
  description = "Short region code used in resource names."
  value       = local.region_short
}

output "gcp_project_id" {
  description = "GCP project ID."
  value       = var.gcp_project_id
}

output "vpc_network_name" {
  description = "VPC network name."
  value       = var.provision_vpc ? google_compute_network.this[0].name : null
}

output "vpc_network_self_link" {
  description = "VPC network self link."
  value       = local.vpc_network_self_link
}

output "gke_subnet_name" {
  description = "GKE subnet name."
  value       = var.provision_vpc ? google_compute_subnetwork.gke[0].name : null
}

output "gke_subnet_self_link" {
  description = "GKE subnet self link."
  value       = local.gke_subnet_self_link
}

output "gke_pods_secondary_range_name" {
  description = "GKE pods secondary range name."
  value       = local.gke_pods_secondary_range_name
}

output "gke_services_secondary_range_name" {
  description = "GKE services secondary range name."
  value       = local.gke_svcs_secondary_range_name
}

output "gke_cluster_name" {
  description = "GKE cluster name used by idp-installer-gcp."
  value       = local.provision_gke ? (var.gke_autopilot_enabled ? google_container_cluster.autopilot[0].name : google_container_cluster.standard[0].name) : null
}

output "cluster_name" {
  description = "Cluster name alias for GitOps compatibility."
  value       = local.provision_gke ? (var.gke_autopilot_enabled ? google_container_cluster.autopilot[0].name : google_container_cluster.standard[0].name) : null
}

output "kubernetes_cluster_name" {
  description = "Cluster name alias for GitOps compatibility."
  value       = local.provision_gke ? (var.gke_autopilot_enabled ? google_container_cluster.autopilot[0].name : google_container_cluster.standard[0].name) : null
}

output "gke_cluster_endpoint" {
  description = "GKE cluster HTTPS endpoint."
  value       = local.provision_gke ? "https://${var.gke_autopilot_enabled ? google_container_cluster.autopilot[0].endpoint : google_container_cluster.standard[0].endpoint}" : null
}

output "gke_cluster_ca_certificate" {
  description = "GKE cluster CA certificate."
  value       = local.provision_gke ? (var.gke_autopilot_enabled ? google_container_cluster.autopilot[0].master_auth[0].cluster_ca_certificate : google_container_cluster.standard[0].master_auth[0].cluster_ca_certificate) : null
  sensitive   = true
}

output "gke_location" {
  description = "GKE cluster location."
  value       = local.gke_location
}

output "gke_location_type" {
  description = "GKE location type."
  value       = var.gke_location_type
}

output "gke_workload_identity_pool" {
  description = "GKE Workload Identity pool."
  value       = "${var.gcp_project_id}.svc.id.goog"
}

output "gke_node_service_account_email" {
  description = "GKE standard node service account email."
  value       = local.gke_node_service_account_email
}

output "workload_identity_service_accounts" {
  description = "Created Workload Identity service accounts and Kubernetes annotations."
  value = {
    for name, service_account in google_service_account.workload_identity : name => {
      email      = service_account.email
      member     = local.workload_identity_members[name]
      namespace  = local.workload_identity_bindings_normalized[name].namespace
      annotation = "iam.gke.io/gcp-service-account=${service_account.email}"
      ksa_name   = local.workload_identity_bindings_normalized[name].kubernetes_service_account
    }
  }
}

output "external_dns_service_account_email" {
  description = "GCP service account email for external-dns."
  value       = try(google_service_account.workload_identity["external-dns"].email, null)
}

output "cert_manager_service_account_email" {
  description = "GCP service account email for cert-manager."
  value       = try(google_service_account.workload_identity["cert-manager"].email, null)
}

output "external_secrets_service_account_email" {
  description = "GCP service account email for external-secrets."
  value       = try(google_service_account.workload_identity["external-secrets"].email, null)
}

output "artifact_registry_repository_names" {
  description = "Artifact Registry repository names."
  value       = { for key, repo in google_artifact_registry_repository.repositories : key => repo.repository_id }
}

output "artifact_registry_repository_urls" {
  description = "Artifact Registry repository URLs for Docker repositories."
  value = {
    for key, repo in google_artifact_registry_repository.repositories :
    key => "${repo.location}-docker.pkg.dev/${var.gcp_project_id}/${repo.repository_id}"
    if repo.format == "DOCKER"
  }
}

output "ecr_repository_names" {
  description = "AWS compatibility alias for Artifact Registry repository names."
  value       = { for key, repo in google_artifact_registry_repository.repositories : key => repo.repository_id }
}

output "ecr_repository_urls_map" {
  description = "AWS compatibility alias for Artifact Registry repository URLs."
  value = {
    for key, repo in google_artifact_registry_repository.repositories :
    key => "${repo.location}-docker.pkg.dev/${var.gcp_project_id}/${repo.repository_id}"
    if repo.format == "DOCKER"
  }
}

output "custom_secret_names" {
  description = "Secret Manager custom secret IDs."
  value       = { for key, secret in google_secret_manager_secret.custom : key => secret.secret_id }
}

output "custom_secret_ids" {
  description = "Secret Manager custom secret resource IDs."
  value       = { for key, secret in google_secret_manager_secret.custom : key => secret.id }
}

output "custom_secret_versions" {
  description = "Secret Manager custom secret versions."
  value       = { for key, version in google_secret_manager_secret_version.custom : key => version.name }
}

output "custom_secret_values" {
  description = "Generated or provided custom secret payloads."
  value       = local.custom_secret_payloads
  sensitive   = true
}

output "cloudsql_instance_name" {
  description = "Cloud SQL instance name."
  value       = local.create_cloudsql_postgres ? google_sql_database_instance.postgres[0].name : null
}

output "cloudsql_connection_name" {
  description = "Cloud SQL connection name."
  value       = local.create_cloudsql_postgres ? google_sql_database_instance.postgres[0].connection_name : null
}

output "cloudsql_private_ip_address" {
  description = "Cloud SQL private IP address."
  value       = local.create_cloudsql_postgres ? google_sql_database_instance.postgres[0].private_ip_address : null
}

output "cloudsql_database_name" {
  description = "Cloud SQL default database name."
  value       = local.create_cloudsql_postgres && var.cloudsql_database_name != "" ? google_sql_database.main[0].name : null
}

output "cloudsql_admin_secret_name" {
  description = "Secret Manager secret containing the Cloud SQL admin password."
  value       = local.create_cloudsql_postgres ? google_secret_manager_secret.cloudsql_admin[0].secret_id : null
}

output "cloudsql_extra_secret_name" {
  description = "Secret Manager secret containing the Cloud SQL extra user password."
  value       = local.create_cloudsql_postgres && var.cloudsql_create_extra_user ? google_secret_manager_secret.cloudsql_extra[0].secret_id : null
}

output "rds_cluster_endpoint" {
  description = "AWS compatibility alias for Cloud SQL private IP."
  value       = local.create_cloudsql_postgres ? google_sql_database_instance.postgres[0].private_ip_address : null
}

output "rds_master_credentials_secret_name" {
  description = "AWS compatibility alias for the Cloud SQL admin password secret."
  value       = local.create_cloudsql_postgres ? google_secret_manager_secret.cloudsql_admin[0].secret_id : null
}

output "rds_extra_credentials_secret_name" {
  description = "AWS compatibility alias for the Cloud SQL extra password secret."
  value       = local.create_cloudsql_postgres && var.cloudsql_create_extra_user ? google_secret_manager_secret.cloudsql_extra[0].secret_id : null
}

output "memorystore_redis_host" {
  description = "Memorystore Redis host."
  value       = local.create_memorystore_redis ? google_redis_instance.redis[0].host : null
}

output "memorystore_redis_port" {
  description = "Memorystore Redis port."
  value       = local.create_memorystore_redis ? google_redis_instance.redis[0].port : null
}

output "redis_primary_endpoint_address" {
  description = "AWS compatibility alias for Memorystore Redis host."
  value       = local.create_memorystore_redis ? google_redis_instance.redis[0].host : null
}

output "redis_reader_endpoint_address" {
  description = "AWS compatibility alias for Memorystore Redis host."
  value       = local.create_memorystore_redis ? google_redis_instance.redis[0].host : null
}

output "gcs_bucket_names" {
  description = "Created GCS bucket names."
  value       = { for key, bucket in google_storage_bucket.buckets : key => bucket.name }
}

output "s3_bucket_names" {
  description = "AWS compatibility alias for GCS bucket names."
  value       = { for key, bucket in google_storage_bucket.buckets : key => bucket.name }
}

output "pubsub_topic_names" {
  description = "Created Pub/Sub topic names."
  value       = { for key, topic in google_pubsub_topic.topics : key => topic.name }
}

output "pubsub_subscription_names" {
  description = "Created Pub/Sub subscription names."
  value       = { for key, subscription in google_pubsub_subscription.subscriptions : key => subscription.name }
}

output "firestore_database_name" {
  description = "Firestore database name."
  value       = local.create_firestore ? google_firestore_database.this[0].name : null
}

output "dns_managed_zone" {
  description = "Cloud DNS managed zone name."
  value       = var.dns_managed_zone
}

output "dns_managed_zone_dns_name" {
  description = "Cloud DNS managed zone DNS name when created or looked up."
  value       = try(google_dns_managed_zone.this[0].dns_name, try(data.google_dns_managed_zone.existing[0].dns_name, null))
}

output "cloud_armor_policy_name" {
  description = "Cloud Armor policy name."
  value       = local.cloud_armor_enabled ? google_compute_security_policy.application[0].name : null
}

output "waf_webacl_arn" {
  description = "AWS compatibility alias for Cloud Armor policy self link."
  value       = local.cloud_armor_enabled ? google_compute_security_policy.application[0].self_link : null
}

