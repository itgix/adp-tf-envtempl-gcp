# ADP Terraform Environment Template for GCP

This repository is the GCP landing-zone and ADP platform Terraform template for
`idp-installer-gcp`. It mirrors the intent of the AWS environment template with
native Google Cloud resources.

## What It Creates

- Google APIs required by the selected components.
- VPC, GKE subnet, secondary pod/service ranges, Cloud NAT, and private service
  access.
- Standard or Autopilot GKE with Workload Identity.
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

Deletion protection defaults to `false` for GKE and Cloud SQL so
`idp-installer-gcp/cleanup.sh --tf-destroy` can tear environments down. Turn it
on in long-lived production environments after validating your destroy process.
