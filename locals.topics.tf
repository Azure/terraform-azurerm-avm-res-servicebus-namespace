locals {
  flatten_topic_rules = var.sku != "Basic" ? flatten([
    for topic_name, topic_params in var.topics : [
      for rule_name, rule_params in topic_params.authorization_rules : {
        rule_name  = rule_name
        topic_name = topic_name
        send       = rule_params.send
        listen     = rule_params.listen
        manage     = rule_params.manage
      }
    ]
  ]) : []

  topic_rules = { 
    for topic_rule in local.flatten_topic_rules : 
    "${topic_rule.topic_name}|${topic_rule.rule_name}" => topic_rule
  }
}
