locals {
  gcp_regions_short = {
    "africa-south1"           = "as1"
    "asia-east1"              = "ae1"
    "asia-east2"              = "ae2"
    "asia-northeast1"         = "an1"
    "asia-northeast2"         = "an2"
    "asia-northeast3"         = "an3"
    "asia-south1"             = "as0"
    "asia-south2"             = "as2"
    "asia-southeast1"         = "ase1"
    "asia-southeast2"         = "ase2"
    "australia-southeast1"    = "au1"
    "australia-southeast2"    = "au2"
    "europe-central2"         = "ec2"
    "europe-north1"           = "en1"
    "europe-southwest1"       = "esw1"
    "europe-west1"            = "ew1"
    "europe-west2"            = "ew2"
    "europe-west3"            = "ew3"
    "europe-west4"            = "ew4"
    "europe-west6"            = "ew6"
    "europe-west8"            = "ew8"
    "europe-west9"            = "ew9"
    "europe-west10"           = "ew10"
    "europe-west12"           = "ew12"
    "me-central1"             = "mc1"
    "me-central2"             = "mc2"
    "me-west1"                = "mw1"
    "northamerica-northeast1" = "nn1"
    "northamerica-northeast2" = "nn2"
    "southamerica-east1"      = "se1"
    "southamerica-west1"      = "sw1"
    "us-central1"             = "uc1"
    "us-east1"                = "ue1"
    "us-east4"                = "ue4"
    "us-east5"                = "ue5"
    "us-south1"               = "us1"
    "us-west1"                = "uw1"
    "us-west2"                = "uw2"
    "us-west3"                = "uw3"
    "us-west4"                = "uw4"
  }

  region_short = lookup(local.gcp_regions_short, var.region, replace(var.region, "-", ""))
  name_seed    = trim(substr(replace(lower("${var.project_name}-${var.environment}-${local.region_short}"), "/[^a-z0-9-]/", "-"), 0, 40), "-")
  name_base    = local.name_seed != "" ? local.name_seed : "adp"

  resource_prefix = trim(substr(local.name_base, 0, 30), "-")
  secret_prefix   = "${local.resource_prefix}-"

  common_labels = merge(
    {
      application = "adp"
      environment = substr(replace(lower(var.environment), "/[^a-z0-9_-]/", "_"), 0, 63)
      managed_by  = "terraform"
      project     = substr(replace(lower(var.project_name), "/[^a-z0-9_-]/", "_"), 0, 63)
    },
    var.resources_labels
  )

  provision_gke              = var.provision_gke && var.provision_eks
  create_cloudsql_postgres   = var.create_cloudsql_postgres || var.create_rds
  create_memorystore_redis   = var.create_memorystore_redis || var.create_elasticache_redis
  create_artifact_registry   = var.provision_artifact_registry || try(tobool(var.provision_ecr), false)
  create_pubsub              = var.pubsub_create || try(tobool(var.provision_sqs), false)
  create_firestore           = var.firestore_create || var.ddb_create || var.ddb_global_create
  create_gcs_buckets         = var.gcs_create || var.s3_create
  cloud_armor_enabled        = var.cloud_armor_enabled || var.application_waf_enabled
  private_services_enabled   = var.private_service_access_enabled && (local.create_cloudsql_postgres || local.create_memorystore_redis)
  effective_allowed_cidrs    = length(var.allowed_cidr_blocks) > 0 ? var.allowed_cidr_blocks : var.cluster_endpoint_public_access_cidrs
  cloud_armor_default_action = contains(["block", "deny", "deny(403)"], lower(var.waf_default_action)) ? "deny(403)" : "allow"

  network_name                  = var.vpc_network_name != "" ? var.vpc_network_name : "vpc-${local.resource_prefix}"
  gke_subnet_name               = var.gke_subnet_name != "" ? var.gke_subnet_name : "subnet-gke-${local.resource_prefix}"
  gke_pods_secondary_range_name = var.gke_pods_secondary_range_name
  gke_svcs_secondary_range_name = var.gke_services_secondary_range_name

  gke_subnet_module_key = "${var.region}/${local.gke_subnet_name}"
  vpc_network_id        = var.provision_vpc ? module.vpc[0].id : var.vpc_network_self_link
  vpc_network_name      = var.provision_vpc ? module.vpc[0].name : local.network_name
  vpc_network_self_link = var.provision_vpc ? module.vpc[0].self_link : var.vpc_network_self_link
  gke_subnet_id         = var.provision_vpc ? module.vpc[0].subnet_ids[local.gke_subnet_module_key] : var.vpc_subnetwork_self_link
  gke_subnet_self_link  = var.provision_vpc ? module.vpc[0].subnet_self_links[local.gke_subnet_module_key] : var.vpc_subnetwork_self_link

  gke_location                = var.gke_location != "" ? var.gke_location : var.region
  gke_cluster_name            = var.gke_cluster_name != "" ? var.gke_cluster_name : "gke-${local.resource_prefix}"
  gke_node_service_account_id = trim(substr("gke-node-${local.resource_prefix}", 0, 30), "-")
  gke_node_tag                = "gke-${local.resource_prefix}"
  gke_node_service_account_email = var.gke_node_service_account_email != "" ? var.gke_node_service_account_email : (
    local.provision_gke && !var.gke_autopilot_enabled ? module.gke_node_service_account[0].email : null
  )
  gke_cluster_output_name = local.provision_gke ? (
    var.gke_autopilot_enabled ? module.gke_autopilot[0].name : module.gke_standard[0].name
  ) : null
  gke_cluster_output_endpoint = local.provision_gke ? (
    var.gke_autopilot_enabled ? module.gke_autopilot[0].endpoint : module.gke_standard[0].endpoint
  ) : null
  gke_cluster_output_ca_certificate = local.provision_gke ? (
    var.gke_autopilot_enabled ? module.gke_autopilot[0].ca_certificate : module.gke_standard[0].ca_certificate
  ) : null

  default_artifact_registry_repositories = {
    platform = {
      description   = "ADP platform container images"
      format        = "DOCKER"
      repository_id = "platform"
    }
  }

  legacy_ecr_artifact_repositories = {
    for key, repository_name in var.ecr_names_map : key => {
      description   = "Repository migrated from ecr_names_map"
      format        = "DOCKER"
      repository_id = repository_name
    }
  }

  effective_artifact_registry_repositories = local.create_artifact_registry ? merge(
    local.default_artifact_registry_repositories,
    var.artifact_registry_repositories,
    local.legacy_ecr_artifact_repositories
  ) : {}

  artifact_registry_location = var.artifact_registry_location != "" ? var.artifact_registry_location : var.region

  custom_secrets_by_name = {
    for secret in var.custom_secrets : secret.secret_name => secret
  }

  generated_custom_secrets = {
    for name, secret in local.custom_secrets_by_name : name => secret
    if !try(secret.manual, false)
  }

  manual_custom_secret_values = {
    for name, secret in local.custom_secrets_by_name : name => try(secret.value, "")
    if try(secret.manual, false) && try(secret.value, null) != null
  }

  custom_secret_payloads = merge(
    { for name, password in random_password.custom_secrets : name => password.result },
    local.manual_custom_secret_values
  )

  custom_secret_ids        = { for name, secret in local.custom_secrets_by_name : name => "${local.secret_prefix}${secret.secret_name}" }
  cloudsql_instance_name   = var.cloudsql_instance_name != "" ? var.cloudsql_instance_name : "sql-${local.resource_prefix}"
  cloudsql_admin_secret_id = "${local.secret_prefix}cloudsql-${var.cloudsql_default_username}-password"
  cloudsql_extra_secret_id = "${local.secret_prefix}cloudsql-${var.cloudsql_extra_credentials.username}-password"
  cloudsql_extra_password = local.create_cloudsql_postgres && var.cloudsql_create_extra_user ? (
    try(var.cloudsql_extra_credentials.password, null) != null ? var.cloudsql_extra_credentials.password : random_password.cloudsql_extra[0].result
  ) : null
  cloudsql_database_flags_map = {
    for flag in var.cloudsql_database_flags : flag.name => flag.value
  }
  cloudsql_authorized_networks_map = {
    for network in var.cloudsql_authorized_networks : network.name => network.value
  }
  cloudsql_databases = compact(distinct(concat(
    [var.cloudsql_database_name],
    var.cloudsql_create_extra_user ? [var.cloudsql_extra_credentials.database] : []
  )))
  cloudsql_users = local.create_cloudsql_postgres ? merge(
    {
      (var.cloudsql_default_username) = {
        password = random_password.cloudsql_admin[0].result
        type     = "BUILT_IN"
      }
    },
    var.cloudsql_create_extra_user ? {
      (var.cloudsql_extra_credentials.username) = {
        password = local.cloudsql_extra_password
        type     = "BUILT_IN"
      }
    } : {}
  ) : {}

  secret_manager_custom_secrets = {
    for name, secret_id in local.custom_secret_ids : secret_id => {
      labels = local.common_labels
      versions = contains(keys(local.custom_secret_payloads), name) ? {
        initial = {
          data = local.custom_secret_payloads[name]
        }
      } : {}
    }
  }
  secret_manager_cloudsql_secrets = local.create_cloudsql_postgres ? merge(
    {
      (local.cloudsql_admin_secret_id) = {
        labels = local.common_labels
        versions = {
          initial = {
            data = random_password.cloudsql_admin[0].result
          }
        }
      }
    },
    var.cloudsql_create_extra_user ? {
      (local.cloudsql_extra_secret_id) = {
        labels = local.common_labels
        versions = {
          initial = {
            data = local.cloudsql_extra_password
          }
        }
      }
    } : {}
  ) : {}
  secret_manager_secrets = merge(
    local.secret_manager_custom_secrets,
    local.secret_manager_cloudsql_secrets
  )

  default_workload_identity_bindings = var.create_default_workload_identity_bindings ? {
    cert-manager = {
      description                = "Cloud DNS access for cert-manager DNS-01 challenges"
      kubernetes_service_account = "cert-manager"
      namespace                  = "cert-manager"
      roles                      = ["roles/dns.admin"]
    }
    external-dns = {
      description                = "Cloud DNS access for external-dns"
      kubernetes_service_account = "external-dns"
      namespace                  = "external-dns"
      roles                      = ["roles/dns.admin"]
    }
    external-secrets = {
      description                = "Secret Manager access for external-secrets"
      kubernetes_service_account = "external-secrets"
      namespace                  = "external-secrets"
      roles                      = ["roles/secretmanager.secretAccessor"]
    }
  } : {}

  workload_identity_bindings_normalized = {
    for name, binding in merge(local.default_workload_identity_bindings, var.workload_identity_bindings) : name => {
      description                = try(binding.description, "Workload Identity service account for ${name}")
      kubernetes_service_account = try(binding.kubernetes_service_account, try(binding.ksa_name, name))
      namespace                  = try(binding.namespace, "default")
      roles                      = try(binding.roles, [])
    }
  }

  workload_identity_role_bindings = flatten([
    for name, binding in local.workload_identity_bindings_normalized : [
      for role in binding.roles : {
        key  = "${name}:${role}"
        name = name
        role = role
      }
    ]
  ])

  workload_identity_members = {
    for name, binding in local.workload_identity_bindings_normalized :
    name => "serviceAccount:${var.gcp_project_id}.svc.id.goog[${binding.namespace}/${binding.kubernetes_service_account}]"
  }

  effective_bucket_configuration = local.create_gcs_buckets ? {
    for bucket in var.bucket_configuration : bucket.bucket_name_suffix => bucket
  } : {}

  legacy_pubsub_topics = {
    for name, topic in var.sns_topics : name => topic
  }

  legacy_pubsub_subscriptions = {
    for name, queue in var.sqs_queues : name => {
      ack_deadline_seconds       = try(queue.ack_deadline_seconds, 20)
      message_retention_duration = try(queue.message_retention_duration, "604800s")
      topic                      = try(queue.sns_topic_name, "")
    }
    if try(queue.sns_topic_name, "") != ""
  }

  effective_pubsub_topics        = local.create_pubsub ? merge(local.legacy_pubsub_topics, var.pubsub_topics) : {}
  effective_pubsub_subscriptions = local.create_pubsub ? merge(local.legacy_pubsub_subscriptions, var.pubsub_subscriptions) : {}
  pubsub_subscriptions_by_topic = {
    for topic_key, topic in local.effective_pubsub_topics : topic_key => {
      for sub_key, sub in local.effective_pubsub_subscriptions : try(sub.name, sub_key) => {
        ack_deadline_seconds       = try(sub.ack_deadline_seconds, 20)
        labels                     = merge(local.common_labels, try(sub.labels, {}))
        message_retention_duration = try(sub.message_retention_duration, "604800s")
        retain_acked_messages      = try(sub.retain_acked_messages, false)
      }
      if try(sub.topic, "") == topic_key || try(sub.topic, "") == try(topic.name, topic_key)
    }
  }

  dns_zone_domain = var.dns_zone_dns_name != "" ? var.dns_zone_dns_name : "${trim(var.dns_main_domain, ".")}."
  dns_zone_config = var.create_dns_managed_zone ? {
    domain = local.dns_zone_domain
    private = var.dns_zone_visibility == "private" ? {
      client_networks = [local.vpc_network_self_link]
    } : null
    public = var.dns_zone_visibility == "private" ? null : {}
  } : null

  required_project_services = toset(distinct(concat(
    [
      "cloudresourcemanager.googleapis.com",
      "compute.googleapis.com",
      "container.googleapis.com",
      "iam.googleapis.com",
      "iamcredentials.googleapis.com",
      "serviceusage.googleapis.com",
    ],
    var.enable_secret_manager || length(var.custom_secrets) > 0 || local.create_cloudsql_postgres ? ["secretmanager.googleapis.com"] : [],
    local.create_artifact_registry ? ["artifactregistry.googleapis.com"] : [],
    local.create_cloudsql_postgres ? ["servicenetworking.googleapis.com", "sqladmin.googleapis.com"] : [],
    local.create_memorystore_redis ? ["redis.googleapis.com", "servicenetworking.googleapis.com"] : [],
    local.create_pubsub ? ["pubsub.googleapis.com"] : [],
    local.create_firestore ? ["firestore.googleapis.com"] : [],
    var.dns_managed_zone != "" || var.create_dns_managed_zone ? ["dns.googleapis.com"] : []
  )))
}
