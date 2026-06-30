module "vpc" {
  count = var.provision_vpc ? 1 : 0

  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/net-vpc?ref=v54.3.0&depth=1"

  project_id               = var.gcp_project_id
  name                     = local.network_name
  description              = "ADP landing-zone network for ${var.project_name}/${var.environment}"
  auto_create_subnetworks  = false
  create_googleapis_routes = null
  subnets = [
    {
      name                  = local.gke_subnet_name
      region                = var.region
      ip_cidr_range         = var.gke_subnet_cidr
      enable_private_access = true
      secondary_ip_ranges = {
        (local.gke_pods_secondary_range_name) = {
          ip_cidr_range = var.gke_pods_secondary_cidr
        }
        (local.gke_svcs_secondary_range_name) = {
          ip_cidr_range = var.gke_services_secondary_cidr
        }
      }
    }
  ]
  psa_configs = local.private_services_enabled ? [
    {
      ranges = {
        "psa-${local.resource_prefix}" = var.private_service_access_cidr
      }
      labels = local.common_labels
    }
  ] : []

  depends_on = [module.project_services]
}

module "cloud_nat" {
  count = var.enable_cloud_nat ? 1 : 0

  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/net-cloudnat?ref=v54.3.0&depth=1"

  project_id     = var.gcp_project_id
  region         = var.region
  name           = "nat-${local.resource_prefix}"
  router_name    = "router-${local.resource_prefix}"
  router_network = local.vpc_network_self_link
  config_port_allocation = {
    min_ports_per_vm = var.cloud_nat_min_ports_per_vm
  }

  depends_on = [module.vpc]
}

module "vpc_firewall" {
  count = var.create_internal_firewall_rules && var.provision_vpc ? 1 : 0

  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/net-vpc-firewall?ref=v54.3.0&depth=1"

  project_id = var.gcp_project_id
  network    = local.vpc_network_name
  default_rules_config = {
    disabled = true
  }
  ingress_rules = {
    internal = {
      description   = "Allow internal ADP traffic."
      priority      = 1000
      source_ranges = [var.vpc_cidr, var.gke_pods_secondary_cidr, var.gke_services_secondary_cidr]
      rules = [
        { protocol = "icmp" },
        { protocol = "tcp", ports = ["0-65535"] },
        { protocol = "udp", ports = ["0-65535"] },
      ]
    }
    gke-health-checks = {
      description   = "Allow GKE and load-balancer health checks."
      priority      = 1000
      source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
      targets       = [local.gke_node_tag]
      rules = [
        { protocol = "tcp", ports = ["80", "443", "10256", "30000-32767"] },
      ]
    }
  }

  depends_on = [module.vpc]
}
