resource "google_pubsub_topic" "topics" {
  for_each = local.effective_pubsub_topics

  labels  = merge(local.common_labels, try(each.value.labels, {}))
  name    = try(each.value.name, each.key)
  project = var.gcp_project_id

  depends_on = [google_project_service.required]
}

resource "google_pubsub_subscription" "subscriptions" {
  for_each = local.effective_pubsub_subscriptions

  ack_deadline_seconds       = try(each.value.ack_deadline_seconds, 20)
  labels                     = merge(local.common_labels, try(each.value.labels, {}))
  message_retention_duration = try(each.value.message_retention_duration, "604800s")
  name                       = try(each.value.name, each.key)
  project                    = var.gcp_project_id
  retain_acked_messages      = try(each.value.retain_acked_messages, false)
  topic                      = try(google_pubsub_topic.topics[each.value.topic].name, each.value.topic)
}

