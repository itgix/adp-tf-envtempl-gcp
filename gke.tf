module "gke_node_service_account" {
  count = local.provision_gke && !var.gke_autopilot_enabled && var.gke_node_service_account_email == "" ? 1 : 0

  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/iam-service-account?ref=v54.3.0&depth=1"

  project_id   = var.gcp_project_id
  name         = local.gke_node_service_account_id
  display_name = "GKE nodes for ${local.gke_cluster_name}"

  depends_on = [module.project_services]
}

resource "google_project_iam_member" "gke_nodes" {
  for_each = local.provision_gke && !var.gke_autopilot_enabled && var.gke_node_service_account_email == "" ? toset([
    "roles/artifactregistry.reader",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
  ]) : toset([])

  project = var.gcp_project_id
  role    = each.key
  member  = "serviceAccount:${module.gke_node_service_account[0].email}"
}

module "gke_standard" {
  count = local.provision_gke && !var.gke_autopilot_enabled ? 1 : 0

  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/gke-cluster-standard?ref=v54.3.0&depth=1"

  project_id          = var.gcp_project_id
  name                = local.gke_cluster_name
  location            = local.gke_location
  labels              = local.common_labels
  min_master_version  = var.gke_cluster_version
  release_channel     = var.gke_release_channel
  deletion_protection = var.gke_deletion_protection
  node_locations      = var.gke_node_zones
  default_nodepool = {
    remove_pool        = true
    initial_node_count = 1
  }
  vpc_config = {
    network    = local.vpc_network_self_link
    subnetwork = local.gke_subnet_self_link
    secondary_range_names = {
      pods     = local.gke_pods_secondary_range_name
      services = local.gke_svcs_secondary_range_name
    }
  }
  access_config = {
    private_nodes          = var.gke_private_nodes
    master_ipv4_cidr_block = var.gke_master_ipv4_cidr_block
    ip_access = {
      authorized_ranges       = { for idx, cidr in local.effective_allowed_cidrs : "allowed-${idx}" => cidr }
      disable_public_endpoint = var.gke_private_endpoint
      private_endpoint_config = {
        global_access = var.gke_master_global_access_enabled
      }
    }
  }
  enable_addons = {
    dns_cache                      = false
    gce_persistent_disk_csi_driver = true
    gcp_filestore_csi_driver       = false
    gcs_fuse_csi_driver            = false
    horizontal_pod_autoscaling     = true
    http_load_balancing            = true
  }
  enable_features = {
    cost_management     = true
    dataplane_v2        = false
    fqdn_network_policy = false
    workload_identity   = true
  }
  logging_config = {
    enable_system_logs    = contains(var.gke_logging_components, "SYSTEM_COMPONENTS")
    enable_workloads_logs = contains(var.gke_logging_components, "WORKLOADS")
  }
  monitoring_config = {
    enable_system_metrics     = contains(var.gke_monitoring_components, "SYSTEM_COMPONENTS")
    enable_managed_prometheus = var.gke_managed_prometheus_enabled
  }
  node_config = {
    service_account               = local.gke_node_service_account_email
    tags                          = [local.gke_node_tag]
    workload_metadata_config_mode = "GKE_METADATA"
  }

  depends_on = [module.vpc]
}

module "gke_nodepool_primary" {
  count = local.provision_gke && !var.gke_autopilot_enabled ? 1 : 0

  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/gke-nodepool?ref=v54.3.0&depth=1"

  project_id     = var.gcp_project_id
  name           = "np-primary"
  cluster_name   = module.gke_standard[0].name
  cluster_id     = module.gke_standard[0].id
  location       = local.gke_location
  node_locations = length(var.gke_node_zones) > 0 ? var.gke_node_zones : null
  labels         = local.common_labels
  k8s_labels     = local.common_labels
  tags           = [local.gke_node_tag]
  node_count = {
    initial = var.gke_location_type == "region" ? 1 : var.gke_node_desired_count
  }
  nodepool_config = {
    autoscaling = {
      location_policy = "BALANCED"
      max_node_count  = var.gke_node_max_count
      min_node_count  = var.gke_node_min_count
      use_total_nodes = var.gke_location_type == "region"
    }
    management = {
      auto_repair  = true
      auto_upgrade = true
    }
    upgrade_settings = {
      max_surge       = var.gke_node_max_surge
      max_unavailable = var.gke_node_max_unavailable
    }
  }
  node_config = {
    boot_disk = {
      size_gb = var.gke_disk_size_gb
      type    = var.gke_disk_type
    }
    image_type                    = var.gke_image_type
    machine_type                  = var.gke_machine_type
    metadata                      = { disable-legacy-endpoints = "true" }
    preemptible                   = var.gke_spot_nodes ? false : var.gke_preemptible_nodes
    spot                          = var.gke_spot_nodes
    workload_metadata_config_mode = "GKE_METADATA"
  }
  service_account = {
    create       = false
    email        = local.gke_node_service_account_email
    oauth_scopes = var.gke_node_oauth_scopes
  }

  depends_on = [google_project_iam_member.gke_nodes]
}

module "gke_autopilot" {
  count = local.provision_gke && var.gke_autopilot_enabled ? 1 : 0

  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/gke-cluster-autopilot?ref=v54.3.0&depth=1"

  project_id          = var.gcp_project_id
  name                = local.gke_cluster_name
  location            = local.gke_location
  labels              = local.common_labels
  min_master_version  = var.gke_cluster_version
  release_channel     = var.gke_release_channel
  deletion_protection = var.gke_deletion_protection
  node_locations      = var.gke_node_zones
  vpc_config = {
    network    = local.vpc_network_self_link
    subnetwork = local.gke_subnet_self_link
    secondary_range_names = {
      pods     = local.gke_pods_secondary_range_name
      services = local.gke_svcs_secondary_range_name
    }
  }
  access_config = {
    private_nodes          = var.gke_private_nodes
    master_ipv4_cidr_block = var.gke_master_ipv4_cidr_block
    ip_access = {
      authorized_ranges       = { for idx, cidr in local.effective_allowed_cidrs : "allowed-${idx}" => cidr }
      disable_public_endpoint = var.gke_private_endpoint
      private_endpoint_config = {
        global_access = var.gke_master_global_access_enabled
      }
    }
  }
  enable_features = {
    cost_management   = true
    workload_identity = true
  }
  monitoring_config = {
    enable_managed_prometheus = var.gke_managed_prometheus_enabled
  }
  node_config = {
    tags                          = [local.gke_node_tag]
    workload_metadata_config_mode = "GKE_METADATA"
  }

  depends_on = [module.vpc]
}
