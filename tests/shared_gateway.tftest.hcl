mock_provider "google" {
  mock_data "google_dns_managed_zone" {
    defaults = {
      name       = "platform-zone"
      dns_name   = "example.com."
      visibility = "public"
    }
  }
  mock_resource "google_certificate_manager_dns_authorization" {
    defaults = {
      dns_resource_record = [{
        name = "_acme-challenge.example.com."
        type = "CNAME"
        data = "authorization.certificatemanager.goog."
      }]
    }
  }
}
mock_provider "google-beta" {}
mock_provider "random" {}

variables {
  gcp_project_id                            = "test-project"
  project_name                              = "test"
  environment                               = "dev"
  region                                    = "europe-west1"
  provision_gke                             = false
  provision_vpc                             = false
  create_default_workload_identity_bindings = false
  provision_artifact_registry               = false
  enable_secret_manager                     = false
  enable_project_services                   = false
  dns_managed_zone                          = "platform-zone"
  dns_main_domain                           = "example.com"
}

run "disabled_by_default" {
  command = plan
  assert {
    condition     = length(google_compute_global_address.shared_gateway) == 0 && length(google_certificate_manager_certificate.shared_gateway) == 0
    error_message = "Existing environments must not gain shared Gateway resources by default."
  }
}

run "shared_wildcard_gateway" {
  command = plan
  variables {
    gcp_shared_gateway_enabled = true
  }
  assert {
    condition     = length(google_compute_global_address.shared_gateway) == 1 && length(google_certificate_manager_certificate.shared_gateway) == 1
    error_message = "Shared mode must reserve one address and one wildcard certificate."
  }
  assert {
    condition     = google_certificate_manager_certificate.shared_gateway[0].managed[0].domains == tolist(["*.example.com"])
    error_message = "The single managed certificate must cover the configured wildcard domain."
  }
  assert {
    condition     = google_dns_record_set.shared_gateway[0].name == "*.example.com." && google_dns_record_set.shared_gateway[0].type == "A"
    error_message = "Wildcard DNS must point all platform hosts at the shared address."
  }
  assert {
    condition     = google_certificate_manager_dns_authorization.shared_gateway[0].domain == "example.com" && contains(local.required_project_services, "certificatemanager.googleapis.com")
    error_message = "Wildcard issuance requires parent-domain DNS authorization and the Certificate Manager API."
  }
}

run "reject_private_zone" {
  command = plan
  variables {
    gcp_shared_gateway_enabled = true
    dns_zone_visibility        = "private"
  }
  expect_failures = [var.gcp_shared_gateway_enabled]
}

run "reject_missing_zone" {
  command = plan
  variables {
    gcp_shared_gateway_enabled = true
    dns_managed_zone           = ""
  }
  expect_failures = [var.gcp_shared_gateway_enabled]
}

run "reject_unrelated_domain" {
  command = plan
  variables {
    gcp_shared_gateway_enabled = true
    dns_main_domain            = "another-domain.net"
  }
  expect_failures = [google_compute_global_address.shared_gateway[0]]
}
