locals {
  flatten_topic_rules = var.sku != "Basic" ? flatten([
    for topic_name, topic_params in var.topics : [
      for rule_name, rule_params in topic_params.authorization_rules : {
        rule_name   = rule_name
        topic_name  = topic_name
        rule_params = rule_params
      }
    ]
  ]) : []

  topic_rules = { 
    for topic_rule in local.flatten_topic_rules : 
    "${topic_rule.topic_name}|${topic_rule.rule_name}" => topic_rule
  }

  flatten_topic_subscription = var.sku != "Basic" ? flatten([
    for topic_name, topic_params in var.topics : [
      for subscription_name, subscription_params in topic_params.subscriptions : {
        topic_name          = topic_name
        subscription_name   = subscription_name
        subscription_params = subscription_params
      }
    ]
  ]) : []

  topic_subscriptions = {
    for topic_subscription in local.flatten_topic_subscription : 
    "${topic_subscription.topic_name}|${topic_subscription.subscription_name}" => topic_subscription
  }
}
