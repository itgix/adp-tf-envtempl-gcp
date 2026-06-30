resource "google_service_account" "gke_nodes" {
  count = local.provision_gke && !var.gke_autopilot_enabled && var.gke_node_service_account_email == "" ? 1 : 0

  account_id   = local.gke_node_service_account_id
  display_name = "GKE nodes for ${local.gke_cluster_name}"
  project      = var.gcp_project_id

  depends_on = [google_project_service.required]
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
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

resource "google_container_cluster" "standard" {
  count = local.provision_gke && !var.gke_autopilot_enabled ? 1 : 0

  name                     = local.gke_cluster_name
  location                 = local.gke_location
  project                  = var.gcp_project_id
  network                  = local.vpc_network_id
  subnetwork               = local.gke_subnet_id
  networking_mode          = "VPC_NATIVE"
  remove_default_node_pool = true
  initial_node_count       = 1
  min_master_version       = var.gke_cluster_version
  deletion_protection      = var.gke_deletion_protection
  resource_labels          = local.common_labels

  release_channel {
    channel = var.gke_release_channel
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = local.gke_pods_secondary_range_name
    services_secondary_range_name = local.gke_svcs_secondary_range_name
  }

  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  addons_config {
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    http_load_balancing {
      disabled = false
    }
  }

  logging_config {
    enable_components = var.gke_logging_components
  }

  monitoring_config {
    enable_components = var.gke_monitoring_components

    managed_prometheus {
      enabled = var.gke_managed_prometheus_enabled
    }
  }

  dynamic "private_cluster_config" {
    for_each = var.gke_private_nodes || var.gke_private_endpoint ? [1] : []
    content {
      enable_private_endpoint = var.gke_private_endpoint
      enable_private_nodes    = var.gke_private_nodes
      master_ipv4_cidr_block  = var.gke_master_ipv4_cidr_block

      master_global_access_config {
        enabled = var.gke_master_global_access_enabled
      }
    }
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = local.effective_allowed_cidrs
      content {
        cidr_block   = cidr_blocks.value
        display_name = "allowed-${cidr_blocks.key}"
      }
    }
  }

  depends_on = [
    google_compute_subnetwork.gke,
    google_project_service.required,
  ]
}

resource "google_container_node_pool" "primary" {
  count = local.provision_gke && !var.gke_autopilot_enabled ? 1 : 0

  name               = "np-primary"
  cluster            = google_container_cluster.standard[0].name
  initial_node_count = var.gke_location_type == "region" ? 1 : var.gke_node_desired_count
  location           = local.gke_location
  node_locations     = length(var.gke_node_zones) > 0 ? var.gke_node_zones : null
  project            = var.gcp_project_id

  autoscaling {
    location_policy      = "BALANCED"
    max_node_count       = var.gke_location_type == "zone" ? var.gke_node_max_count : null
    min_node_count       = var.gke_location_type == "zone" ? var.gke_node_min_count : null
    total_max_node_count = var.gke_location_type == "region" ? var.gke_node_max_count : null
    total_min_node_count = var.gke_location_type == "region" ? var.gke_node_min_count : null
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    disk_size_gb    = var.gke_disk_size_gb
    disk_type       = var.gke_disk_type
    image_type      = var.gke_image_type
    labels          = local.common_labels
    machine_type    = var.gke_machine_type
    oauth_scopes    = var.gke_node_oauth_scopes
    preemptible     = var.gke_spot_nodes ? false : var.gke_preemptible_nodes
    service_account = local.gke_node_service_account_email
    spot            = var.gke_spot_nodes
    tags            = [local.gke_node_tag]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  upgrade_settings {
    max_surge       = var.gke_node_max_surge
    max_unavailable = var.gke_node_max_unavailable
  }

  depends_on = [
    google_project_iam_member.gke_nodes,
  ]
}

resource "google_container_cluster" "autopilot" {
  count = local.provision_gke && var.gke_autopilot_enabled ? 1 : 0

  name                = local.gke_cluster_name
  location            = local.gke_location
  project             = var.gcp_project_id
  network             = local.vpc_network_id
  subnetwork          = local.gke_subnet_id
  enable_autopilot    = true
  min_master_version  = var.gke_cluster_version
  deletion_protection = var.gke_deletion_protection
  resource_labels     = local.common_labels

  release_channel {
    channel = var.gke_release_channel
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = local.gke_pods_secondary_range_name
    services_secondary_range_name = local.gke_svcs_secondary_range_name
  }

  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  dynamic "private_cluster_config" {
    for_each = var.gke_private_nodes || var.gke_private_endpoint ? [1] : []
    content {
      enable_private_endpoint = var.gke_private_endpoint
      enable_private_nodes    = var.gke_private_nodes
      master_ipv4_cidr_block  = var.gke_master_ipv4_cidr_block

      master_global_access_config {
        enabled = var.gke_master_global_access_enabled
      }
    }
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = local.effective_allowed_cidrs
      content {
        cidr_block   = cidr_blocks.value
        display_name = "allowed-${cidr_blocks.key}"
      }
    }
  }

  depends_on = [
    google_compute_subnetwork.gke,
    google_project_service.required,
  ]
}
