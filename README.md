# ADP Terraform Environment Template for GCP

This repository is the GCP landing-zone and ADP platform Terraform template for
`idp-installer-gcp`. It mirrors the intent of the AWS environment template with
Google Cloud resources, primarily via Google Cloud Foundation Fabric modules.

## What It Creates

- Google APIs required by the selected components.
- VPC, GKE subnet, secondary pod/service ranges, Cloud NAT, and private service
  access through Cloud Foundation Fabric.
- Standard or Autopilot GKE with Workload Identity through Cloud Foundation
  Fabric.
- Default Workload Identity service accounts for `external-dns`,
  `cert-manager`, and `external-secrets`.
- Artifact Registry repositories for platform images.
- Secret Manager secrets, including generated custom secret values.
- Optional Cloud SQL for PostgreSQL.
- Optional Memorystore for Redis.
- Optional GCS buckets.
- Optional Pub/Sub topics/subscriptions.
- Optional Firestore database.
- Optional Cloud DNS managed zone creation/lookup.
- Optional Cloud Armor security policy.
- Optional shared GKE Gateway prerequisites: one global static public IPv4,
  wildcard Cloud DNS A record, DNS authorization CNAME, and a Google-managed
  wildcard certificate with its Certificate Manager map.

## Shared GCP Gateway

Set these keys in the installer environment YAML, using matching installer and
GitOps templates that support the shared Gateway:

```yaml
gcp_shared_gateway_enabled: true
dns_main_domain: "adp8d13.itgix.eu"
dns_managed_zone: "adp8d13-test-itgix-eu"
# Set true only when this template should create the zone.
create_dns_managed_zone: true
```

The opt-in defaults to `false`, leaving existing deployments unchanged. When
enabled, Terraform enables Gateway API on managed Standard/Autopilot clusters,
adds `certificatemanager.googleapis.com` to required APIs, and creates the address,
DNS records and one certificate for `*.dns_main_domain`. It exports
`gcp_shared_gateway_enabled`, `gcp_gateway_address_name`, `gcp_gateway_ip_address`,
and `gcp_gateway_certificate_map` into the installer's `infra-facts.yaml` contract.
The matching GitOps template creates the actual Gateway/load balancer and routes;
Terraform does not create Kubernetes resources or another load balancer.

The selected zone must be public, contain the domain, and be delegated publicly
from its parent. This template creates records in it, but does not change the
parent domain's delegation. For an existing zone, leave `create_dns_managed_zone`
false; shared mode reads and validates it regardless of `lookup_dns_managed_zone`.
Certificate issuance/renewal relies on the authorization CNAME remaining publicly
resolvable. Restrictive existing CAA records must also permit the issuing CA.
The installer identity must be allowed to manage global addresses, DNS records,
Certificate Manager resources, and API enablement (unless managed externally).

A wildcard covers direct subdomains only, not the apex or nested names. The
wildcard DNS record is Terraform-owned; no external-dns deployment is required
for platform hostnames in this mode. Existing explicit A/CNAME records take
precedence over wildcard DNS and must not keep pointing to old load balancers.
Use a dedicated domain/subdomain per Gateway: two Terraform states must not own
the same wildcard A record. The reserved IPv4 and global load balancer remain
billable; backends and health checks are still separate resources per service.

For an externally managed GKE cluster, enable its Standard-channel Gateway API
and HTTP load-balancing add-on separately. Existing per-service GCE ingress
migration can interrupt traffic: remove old ingresses before attaching the same
Services to the Gateway. Apply the reviewed infrastructure plan before updating
GitOps. The Google-managed certificate can remain provisioning until DNS is ready.
No deployment or release-pin update is performed by these local template changes.

Offline verification with installed modules/providers (no real state or credentials):

```bash
terraform validate
```

## Custom Secrets

`custom_secrets` supports any number of Secret Manager secrets. Set `value` to
create an initial version from a manually supplied value, or omit `value` on a
non-manual secret to have Terraform generate one with `random_password`.

## Installer Usage

`idp-installer-gcp` reads `variables.tf` and only passes YAML config keys that
are declared as variables here. A typical config lives in:

```bash
/home/dankata/repos/idp-installer-gcp/config/template.yml
```

The installer generates:

```text
config/<environment>/<region>/terraform.tfvars
config/<environment>/<region>/backend.tfvars
```

The backend is GCS:

```hcl
terraform {
  backend "gcs" {}
}
```

`backends/backend.tfvars` is only a placeholder; the installer overwrites the
bucket and prefix before bootstrapping the destination environment repository.

## Required Inputs

The core required variables are:

- `gcp_project_id`
- `region`
- `environment`
- `project_name`

The installer also requires repository and GitOps fields in its YAML config, but
those are not Terraform variables.

## Important Outputs

The installer expects a supported cluster output. This template exports all
three aliases:

- `gke_cluster_name`
- `cluster_name`
- `kubernetes_cluster_name`

GitOps charts also receive all Terraform outputs through `infra-facts.yaml`,
including service account emails, DNS zone data, Artifact Registry URLs, Secret
Manager secret names, Cloud SQL facts, Memorystore facts, and GCS bucket names.

## Compatibility Aliases

Several AWS template variable/output names are accepted as compatibility aliases:

- `provision_eks` gates GKE creation together with `provision_gke`.
- `provision_ecr` creates Artifact Registry repositories.
- `create_rds` creates Cloud SQL PostgreSQL.
- `create_elasticache_redis` creates Memorystore Redis.
- `s3_create` creates GCS buckets.
- `provision_sqs`, `sns_topics`, and `sqs_queues` map to Pub/Sub.
- `ddb_create` and `ddb_global_create` map to Firestore database creation.
- `application_waf_enabled` creates Cloud Armor.

Prefer the GCP-native variable names for new environments.

## Notes

The selected Cloud Foundation Fabric release requires Terraform `>= 1.12.2`.
This template defaults `terraform_ver` to `1.15.7`; set `terraform_ver:
"1.15.7"` or another compatible newer version in `idp-installer-gcp` configs so
the installer downloads and uses a compatible binary.

The template pins Terraform providers to the latest resolved stable versions:
`hashicorp/google` `7.38.0`, `hashicorp/google-beta` `7.38.0`, and
`hashicorp/random` `3.9.0`. `google-beta` is required by the selected Cloud
Foundation Fabric modules.

Deletion protection defaults to `false` for GKE and Cloud SQL so
`idp-installer-gcp/cleanup.sh --tf-destroy` can tear environments down. Turn it
on in long-lived production environments after validating your destroy process.
