#########################################################################
##                     General Configuration Variables                  ##
#########################################################################

variable "terraform_ver" {
  type        = string
  description = "Terraform version used by idp-installer-gcp. Kept as an allowed config key for generated tfvars."
  default     = "1.15.7"
}

variable "gcp_project_id" {
  type        = string
  description = "GCP project ID where resources are created."
}

variable "region" {
  type        = string
  description = "Primary GCP region."
}

variable "environment" {
  type        = string
  description = "Environment name used in resource naming."
}

variable "project_name" {
  type        = string
  description = "Project, client, or product name used in resource naming."
}

variable "allow_long_names" {
  type        = bool
  description = "Compatibility variable for installer validation."
  default     = true
}

variable "resources_labels" {
  type        = map(string)
  description = "Labels added to resources that support GCP labels."
  default     = {}
}

variable "resources_tags" {
  type        = map(string)
  description = "AWS compatibility input. Prefer resources_labels for GCP resources."
  default     = {}
}

variable "enable_project_services" {
  type        = bool
  description = "Enable required Google APIs with the Cloud Foundation Fabric project module."
  default     = true
}

variable "disable_services_on_destroy" {
  type        = bool
  description = "Whether APIs managed by this template should be disabled during terraform destroy."
  default     = false
}

#########################################################################
##                          Networking Variables                        ##
#########################################################################

variable "provision_vpc" {
  type        = bool
  description = "Create a VPC network and GKE subnetwork. Set false to use vpc_network_self_link and vpc_subnetwork_self_link."
  default     = true
}

variable "vpc_cidr" {
  type        = string
  description = "Primary RFC1918 CIDR used by the GCP landing zone."
  default     = "10.51.0.0/16"
}

variable "vpc_network_name" {
  type        = string
  description = "Optional VPC network name. Used for created VPCs and for naming helpers."
  default     = ""
}

variable "vpc_network_self_link" {
  type        = string
  description = "Existing VPC network self link or ID when provision_vpc is false."
  default     = ""
}

variable "vpc_subnetwork_self_link" {
  type        = string
  description = "Existing GKE subnetwork self link or ID when provision_vpc is false."
  default     = ""
}

variable "gke_subnet_name" {
  type        = string
  description = "Optional name for the GKE subnetwork created by this template."
  default     = ""
}

variable "gke_subnet_cidr" {
  type        = string
  description = "Primary subnet CIDR for GKE nodes."
  default     = "10.51.0.0/20"
}

variable "gke_pods_secondary_cidr" {
  type        = string
  description = "Secondary range for GKE pods."
  default     = "10.52.0.0/16"
}

variable "gke_services_secondary_cidr" {
  type        = string
  description = "Secondary range for GKE services."
  default     = "10.53.0.0/20"
}

variable "gke_pods_secondary_range_name" {
  type        = string
  description = "Name of the GKE pods secondary range."
  default     = "gke-pods"
}

variable "gke_services_secondary_range_name" {
  type        = string
  description = "Name of the GKE services secondary range."
  default     = "gke-services"
}

variable "private_service_access_enabled" {
  type        = bool
  description = "Create private service access for Cloud SQL and Memorystore."
  default     = true
}

variable "private_service_access_prefix_length" {
  type        = number
  description = "Compatibility input for native PSA allocation. Fabric-backed networking uses private_service_access_cidr."
  default     = 16
}

variable "private_service_access_cidr" {
  type        = string
  description = "CIDR reserved for Private Service Access peering."
  default     = "10.54.0.0/16"
}

variable "enable_cloud_nat" {
  type        = bool
  description = "Create Cloud Router and Cloud NAT for private GKE nodes."
  default     = true
}

variable "cloud_nat_min_ports_per_vm" {
  type        = number
  description = "Minimum Cloud NAT ports per VM."
  default     = 64
}

variable "create_internal_firewall_rules" {
  type        = bool
  description = "Create baseline internal and load-balancer-health-check firewall rules."
  default     = true
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDRs allowed for GKE master authorized networks and selected managed service access."
  default     = ["0.0.0.0/0"]
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
  description = "AWS compatibility input. Used when allowed_cidr_blocks is empty."
  default     = []
}

#########################################################################
##                               DNS                                    ##
#########################################################################

variable "dns_managed_zone" {
  type        = string
  description = "Cloud DNS managed zone name used by GitOps components such as external-dns."
  default     = ""
}

variable "dns_main_domain" {
  type        = string
  description = "Main DNS domain."
  default     = "itgix.eu"
}

variable "create_dns_managed_zone" {
  type        = bool
  description = "Create the Cloud DNS managed zone when true. Otherwise the zone is treated as pre-existing."
  default     = false
}

variable "lookup_dns_managed_zone" {
  type        = bool
  description = "Read the existing Cloud DNS zone with a data source for validation and outputs."
  default     = false
}

variable "dns_zone_dns_name" {
  type        = string
  description = "DNS name for a created Cloud DNS managed zone. Defaults to dns_main_domain with a trailing dot."
  default     = ""
}

variable "dns_zone_visibility" {
  type        = string
  description = "Visibility for created Cloud DNS zone: public or private."
  default     = "public"
}

variable "dns_zone_description" {
  type        = string
  description = "Description for created Cloud DNS zone."
  default     = "ADP managed DNS zone"
}

#########################################################################
##                               GKE                                    ##
#########################################################################

variable "provision_gke" {
  type        = bool
  description = "Create a GKE cluster."
  default     = true
}

variable "provision_eks" {
  type        = bool
  description = "AWS compatibility alias. If false, GKE creation is also disabled."
  default     = true
}

variable "gke_cluster_name" {
  type        = string
  description = "Optional explicit GKE cluster name."
  default     = ""
}

variable "gke_location" {
  type        = string
  description = "GKE location. Defaults to region."
  default     = ""
}

variable "gke_location_type" {
  type        = string
  description = "Whether gke_location is a region or zone."
  default     = "region"
}

variable "gke_cluster_version" {
  type        = string
  description = "Desired GKE control plane version or minor version."
  default     = "1.33"
}

variable "gke_release_channel" {
  type        = string
  description = "GKE release channel."
  default     = "REGULAR"
}

variable "gke_deletion_protection" {
  type        = bool
  description = "GKE deletion protection. Defaults false so installer cleanup can destroy the environment."
  default     = false
}

variable "gke_autopilot_enabled" {
  type        = bool
  description = "Create an Autopilot cluster instead of a standard cluster and node pool."
  default     = false
}

variable "gke_private_nodes" {
  type        = bool
  description = "Create private GKE nodes."
  default     = true
}

variable "gke_private_endpoint" {
  type        = bool
  description = "Use a private GKE control-plane endpoint."
  default     = false
}

variable "gke_master_ipv4_cidr_block" {
  type        = string
  description = "CIDR block for the private GKE control plane."
  default     = "172.16.0.0/28"
}

variable "gke_master_global_access_enabled" {
  type        = bool
  description = "Enable global access to the private GKE control plane."
  default     = false
}

variable "gke_node_zones" {
  type        = list(string)
  description = "Optional GKE node zones for regional clusters."
  default     = []
}

variable "gke_node_min_count" {
  type        = number
  description = "Minimum node count for the standard GKE node pool. For regional clusters this is treated as a total count."
  default     = 3
}

variable "gke_node_desired_count" {
  type        = number
  description = "Initial node count for the standard GKE node pool."
  default     = 3
}

variable "gke_node_max_count" {
  type        = number
  description = "Maximum node count for the standard GKE node pool. For regional clusters this is treated as a total count."
  default     = 4
}

variable "gke_machine_type" {
  type        = string
  description = "Machine type for the standard GKE node pool."
  default     = "e2-standard-4"
}

variable "gke_disk_size_gb" {
  type        = number
  description = "Boot disk size in GB for standard GKE nodes."
  default     = 100
}

variable "gke_disk_type" {
  type        = string
  description = "Boot disk type for standard GKE nodes."
  default     = "pd-balanced"
}

variable "gke_image_type" {
  type        = string
  description = "GKE node image type."
  default     = "COS_CONTAINERD"
}

variable "gke_preemptible_nodes" {
  type        = bool
  description = "Use preemptible VMs for standard GKE nodes."
  default     = false
}

variable "gke_spot_nodes" {
  type        = bool
  description = "Use Spot VMs for standard GKE nodes."
  default     = false
}

variable "gke_node_service_account_email" {
  type        = string
  description = "Existing service account email for standard GKE nodes. Leave empty to create one."
  default     = ""
}

variable "gke_node_oauth_scopes" {
  type        = list(string)
  description = "OAuth scopes for standard GKE nodes."
  default     = ["https://www.googleapis.com/auth/cloud-platform"]
}

variable "gke_node_max_surge" {
  type        = number
  description = "Max surge for GKE node upgrades."
  default     = 1
}

variable "gke_node_max_unavailable" {
  type        = number
  description = "Max unavailable nodes during GKE node upgrades."
  default     = 0
}

variable "gke_logging_components" {
  type        = list(string)
  description = "GKE logging components."
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

variable "gke_monitoring_components" {
  type        = list(string)
  description = "GKE monitoring components."
  default     = ["SYSTEM_COMPONENTS"]
}

variable "gke_managed_prometheus_enabled" {
  type        = bool
  description = "Enable Google Managed Service for Prometheus."
  default     = true
}

#########################################################################
##                         Workload Identity                            ##
#########################################################################

variable "create_default_workload_identity_bindings" {
  type        = bool
  description = "Create default GCP service accounts and IAM roles for external-dns, cert-manager, and external-secrets."
  default     = true
}

variable "workload_identity_bindings" {
  type        = map(any)
  description = "Additional Workload Identity bindings keyed by logical name."
  default     = {}
}

#########################################################################
##                         Artifact Registry                            ##
#########################################################################

variable "provision_artifact_registry" {
  type        = bool
  description = "Create Artifact Registry repositories."
  default     = true
}

variable "provision_ecr" {
  type        = any
  description = "AWS compatibility alias for provision_artifact_registry."
  default     = false
}

variable "artifact_registry_location" {
  type        = string
  description = "Artifact Registry location. Defaults to region."
  default     = ""
}

variable "artifact_registry_repositories" {
  type        = map(any)
  description = "Artifact Registry repositories keyed by logical name."
  default     = {}
}

variable "artifact_registry_immutable_tags" {
  type        = bool
  description = "Whether Docker tags are immutable in created repositories."
  default     = true
}

variable "artifact_registry_reader_members" {
  type        = list(string)
  description = "IAM members granted roles/artifactregistry.reader on created repositories."
  default     = []
}

variable "artifact_registry_writer_members" {
  type        = list(string)
  description = "IAM members granted roles/artifactregistry.writer on created repositories."
  default     = []
}

variable "ecr_names_map" {
  type        = map(string)
  description = "AWS compatibility map. Values are created as Docker Artifact Registry repository IDs."
  default     = {}
}

#########################################################################
##                         Secret Manager                               ##
#########################################################################

variable "enable_secret_manager" {
  type        = bool
  description = "Enable and use Secret Manager."
  default     = true
}

variable "custom_secrets" {
  description = "List of custom secrets to create in Secret Manager. Non-manual secrets get generated passwords."
  type = list(object({
    secret_name      = string
    length           = optional(number)
    special          = optional(bool)
    override_special = optional(string)
    keepers          = optional(map(string))
    manual           = optional(bool, false)
    value            = optional(string)
  }))
  default = []
}

variable "custom_secret_keepers" {
  type        = map(map(string))
  description = "Map of random_password keepers for generated custom secrets."
  default     = {}
}

#########################################################################
##                         Cloud SQL PostgreSQL                         ##
#########################################################################

variable "create_cloudsql_postgres" {
  type        = bool
  description = "Create Cloud SQL for PostgreSQL."
  default     = false
}

variable "create_rds" {
  type        = bool
  description = "AWS compatibility alias for create_cloudsql_postgres."
  default     = false
}

variable "cloudsql_instance_name" {
  type        = string
  description = "Optional explicit Cloud SQL instance name."
  default     = ""
}

variable "cloudsql_database_version" {
  type        = string
  description = "Cloud SQL PostgreSQL database version."
  default     = "POSTGRES_17"
}

variable "cloudsql_tier" {
  type        = string
  description = "Cloud SQL machine tier."
  default     = "db-custom-2-7680"
}

variable "cloudsql_availability_type" {
  type        = string
  description = "Cloud SQL availability type: ZONAL or REGIONAL."
  default     = "ZONAL"
}

variable "cloudsql_disk_size_gb" {
  type        = number
  description = "Cloud SQL disk size in GB."
  default     = 50
}

variable "cloudsql_disk_type" {
  type        = string
  description = "Cloud SQL disk type."
  default     = "PD_SSD"
}

variable "cloudsql_backup_enabled" {
  type        = bool
  description = "Enable Cloud SQL backups."
  default     = true
}

variable "cloudsql_backup_start_time" {
  type        = string
  description = "UTC backup start time for Cloud SQL."
  default     = "03:00"
}

variable "cloudsql_point_in_time_recovery_enabled" {
  type        = bool
  description = "Enable point-in-time recovery for Cloud SQL."
  default     = true
}

variable "cloudsql_public_ip_enabled" {
  type        = bool
  description = "Enable public IPv4 address on Cloud SQL."
  default     = false
}

variable "cloudsql_authorized_networks" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Authorized networks for Cloud SQL public IP access."
  default     = []
}

variable "cloudsql_deletion_protection" {
  type        = bool
  description = "Cloud SQL deletion protection."
  default     = false
}

variable "cloudsql_default_username" {
  type        = string
  description = "Cloud SQL admin database username."
  default     = "postgres"
}

variable "cloudsql_database_name" {
  type        = string
  description = "Default application database name."
  default     = "app"
}

variable "cloudsql_database_flags" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Cloud SQL database flags."
  default     = []
}

variable "cloudsql_create_extra_user" {
  type        = bool
  description = "Create an extra database and user for applications."
  default     = true
}

variable "cloudsql_extra_credentials" {
  type = object({
    username = string
    password = optional(string)
    database = string
  })
  description = "Extra Cloud SQL database credentials."
  default = {
    database = "demodb"
    username = "demouser"
  }
}

#########################################################################
##                         Memorystore Redis                            ##
#########################################################################

variable "create_memorystore_redis" {
  type        = bool
  description = "Create Memorystore for Redis."
  default     = false
}

variable "create_elasticache_redis" {
  type        = bool
  description = "AWS compatibility alias for create_memorystore_redis."
  default     = false
}

variable "memorystore_name" {
  type        = string
  description = "Optional explicit Memorystore instance name."
  default     = ""
}

variable "memorystore_tier" {
  type        = string
  description = "Memorystore tier: BASIC or STANDARD_HA."
  default     = "BASIC"
}

variable "memorystore_memory_size_gb" {
  type        = number
  description = "Memorystore memory size in GB."
  default     = 1
}

variable "memorystore_redis_version" {
  type        = string
  description = "Memorystore Redis version."
  default     = "REDIS_7_2"
}

variable "memorystore_location_id" {
  type        = string
  description = "Optional zone for Memorystore primary node."
  default     = ""
}

variable "memorystore_alternative_location_id" {
  type        = string
  description = "Optional zone for Memorystore failover node."
  default     = ""
}

variable "memorystore_connect_mode" {
  type        = string
  description = "Memorystore connect mode."
  default     = "PRIVATE_SERVICE_ACCESS"
}

variable "memorystore_auth_enabled" {
  type        = bool
  description = "Enable AUTH on Memorystore."
  default     = true
}

#########################################################################
##                         GCS Buckets                                  ##
#########################################################################

variable "gcs_create" {
  type        = bool
  description = "Create GCS buckets."
  default     = false
}

variable "s3_create" {
  type        = bool
  description = "AWS compatibility alias for gcs_create."
  default     = false
}

variable "gcs_force_destroy" {
  type        = bool
  description = "Default force_destroy for created GCS buckets."
  default     = false
}

variable "bucket_configuration" {
  type = list(object({
    bucket_name_suffix          = string
    bucket_name                 = optional(string)
    location                    = optional(string)
    storage_class               = optional(string)
    versioning                  = optional(bool)
    versioning_enabled          = optional(bool)
    uniform_bucket_level_access = optional(bool)
    public_access_prevention    = optional(string)
    force_destroy               = optional(bool)
    labels                      = optional(map(string))
    lifecycle_age_days          = optional(number)
    cors_configuration = optional(list(object({
      allowed_headers = list(string)
      allowed_methods = list(string)
      allowed_origins = list(string)
      expose_headers  = list(string)
      max_age_seconds = number
    })), [])
  }))
  description = "GCS bucket configuration."
  default = [{
    bucket_name_suffix          = "bkt"
    storage_class               = "STANDARD"
    uniform_bucket_level_access = true
    versioning                  = true
  }]
}

#########################################################################
##                         Pub/Sub                                      ##
#########################################################################

variable "pubsub_create" {
  type        = bool
  description = "Create Pub/Sub topics and subscriptions."
  default     = false
}

variable "provision_sqs" {
  type        = any
  description = "AWS compatibility alias for pubsub_create."
  default     = false
}

variable "pubsub_topics" {
  type        = map(any)
  description = "Pub/Sub topics keyed by name."
  default     = {}
}

variable "pubsub_subscriptions" {
  type        = map(any)
  description = "Pub/Sub subscriptions keyed by name. Each value should include topic."
  default     = {}
}

variable "sns_topics" {
  type        = map(any)
  description = "AWS compatibility map converted to Pub/Sub topics."
  default     = {}
}

variable "sqs_queues" {
  type        = map(any)
  description = "AWS compatibility map converted to Pub/Sub subscriptions when sns_topic_name is set."
  default     = {}
}

#########################################################################
##                         Firestore                                    ##
#########################################################################

variable "firestore_create" {
  type        = bool
  description = "Create a Firestore database."
  default     = false
}

variable "ddb_create" {
  type        = bool
  description = "AWS compatibility alias for firestore_create."
  default     = false
}

variable "ddb_global_create" {
  type        = bool
  description = "AWS compatibility alias for firestore_create."
  default     = false
}

variable "firestore_database_id" {
  type        = string
  description = "Firestore database ID."
  default     = "(default)"
}

variable "firestore_location" {
  type        = string
  description = "Firestore location. Defaults to region when empty."
  default     = ""
}

variable "firestore_delete_protection" {
  type        = bool
  description = "Enable Firestore delete protection."
  default     = false
}

variable "firestore_deletion_policy" {
  type        = string
  description = "Firestore Terraform deletion policy."
  default     = "DELETE"
}

#########################################################################
##                         Cloud Armor                                  ##
#########################################################################

variable "cloud_armor_enabled" {
  type        = bool
  description = "Create a Cloud Armor security policy."
  default     = false
}

variable "application_waf_enabled" {
  type        = bool
  description = "AWS compatibility alias for cloud_armor_enabled."
  default     = false
}

variable "waf_default_action" {
  type        = string
  description = "Default WAF action. allow or block/deny."
  default     = "allow"
}

variable "cloud_armor_rules" {
  type        = list(any)
  description = "Additional Cloud Armor source-IP rules."
  default     = []
}

#########################################################################
##                         Extension Hook                               ##
#########################################################################

variable "custom_terraform_vars" {
  type        = any
  description = "Object of custom values for extra Terraform files outside the template."
  default     = {}
}
