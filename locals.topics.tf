locals {
  normalized_topics = var.sku != local.basic_sku_name ? {
    for topic_key, topic_params in var.topics : coalesce(topic_params.name, topic_key) => topic_params
  } : {}

  flatten_topic_rules = flatten([
    for topic_name, topic_params in local.normalized_topics : [
      for rule_key, rule_params in topic_params.authorization_rules : {
        topic_name  = topic_name
        rule_params = rule_params
        rule_name   = coalesce(rule_params.name, rule_key)
      }
    ]
  ])

  topic_rules = {
    for topic_rule in local.flatten_topic_rules :
    "${topic_rule.topic_name}|${topic_rule.rule_name}" => topic_rule
  }

  flatten_topic_subscription = flatten([
    for topic_name, topic_params in local.normalized_topics : [
      for subscription_key, subscription_params in topic_params.subscriptions : {
        topic_name          = topic_name
        subscription_params = subscription_params
        subscription_name   = coalesce(subscription_params.name, subscription_key)
      }
    ]
  ])

  topic_subscriptions = {
    for topic_subscription in local.flatten_topic_subscription :
    "${topic_subscription.topic_name}|${topic_subscription.subscription_name}" => topic_subscription
  }

  base_topics = { for k, v in local.topic_subscriptions : k => v if v.subscription_params.forward_to == null && v.subscription_params.forward_dead_lettered_messages_to == null }

  forward_topics = { for k, v in local.topic_subscriptions : k => v if v.subscription_params.forward_to != null || v.subscription_params.forward_dead_lettered_messages_to != null }
}
