resource "google_compute_network" "this" {
  count = var.provision_vpc ? 1 : 0

  name                    = local.network_name
  auto_create_subnetworks = false
  description             = "ADP landing-zone network for ${var.project_name}/${var.environment}"
  project                 = var.gcp_project_id

  depends_on = [google_project_service.required]
}

resource "google_compute_subnetwork" "gke" {
  count = var.provision_vpc ? 1 : 0

  name                     = local.gke_subnet_name
  ip_cidr_range            = var.gke_subnet_cidr
  network                  = google_compute_network.this[0].id
  private_ip_google_access = true
  project                  = var.gcp_project_id
  region                   = var.region

  secondary_ip_range {
    ip_cidr_range = var.gke_pods_secondary_cidr
    range_name    = local.gke_pods_secondary_range_name
  }

  secondary_ip_range {
    ip_cidr_range = var.gke_services_secondary_cidr
    range_name    = local.gke_svcs_secondary_range_name
  }
}

resource "google_compute_router" "nat" {
  count = var.enable_cloud_nat ? 1 : 0

  name    = "router-${local.resource_prefix}"
  network = local.vpc_network_id
  project = var.gcp_project_id
  region  = var.region

  depends_on = [google_compute_network.this]
}

resource "google_compute_router_nat" "this" {
  count = var.enable_cloud_nat ? 1 : 0

  name                               = "nat-${local.resource_prefix}"
  nat_ip_allocate_option             = "AUTO_ONLY"
  project                            = var.gcp_project_id
  region                             = var.region
  router                             = google_compute_router.nat[0].name
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  min_ports_per_vm                   = var.cloud_nat_min_ports_per_vm
}

resource "google_compute_global_address" "private_services" {
  count = local.private_services_enabled ? 1 : 0

  name          = "psa-${local.resource_prefix}"
  address_type  = "INTERNAL"
  prefix_length = var.private_service_access_prefix_length
  purpose       = "VPC_PEERING"
  network       = local.vpc_network_id
  project       = var.gcp_project_id

  depends_on = [google_project_service.required]
}

resource "google_service_networking_connection" "private_services" {
  count = local.private_services_enabled ? 1 : 0

  network                 = local.vpc_network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services[0].name]

  depends_on = [google_project_service.required]
}

resource "google_compute_firewall" "allow_internal" {
  count = var.create_internal_firewall_rules && var.provision_vpc ? 1 : 0

  name    = "fw-internal-${local.resource_prefix}"
  network = google_compute_network.this[0].name
  project = var.gcp_project_id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [
    var.vpc_cidr,
    var.gke_pods_secondary_cidr,
    var.gke_services_secondary_cidr,
  ]
}

resource "google_compute_firewall" "allow_gke_health_checks" {
  count = var.create_internal_firewall_rules && var.provision_vpc ? 1 : 0

  name    = "fw-gke-hc-${local.resource_prefix}"
  network = google_compute_network.this[0].name
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "10256", "30000-32767"]
  }

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22",
  ]

  target_tags = [local.gke_node_tag]
}

