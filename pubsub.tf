module "pubsub" {
  for_each = local.effective_pubsub_topics

  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git//modules/pubsub?ref=v54.3.0&depth=1"

  project_id                 = var.gcp_project_id
  name                       = try(each.value.name, each.key)
  labels                     = merge(local.common_labels, try(each.value.labels, {}))
  message_retention_duration = try(each.value.message_retention_duration, null)
  subscriptions              = try(local.pubsub_subscriptions_by_topic[each.key], {})

  depends_on = [module.project_services]
}
