locals {
  base_queues = { for k, v in local.normalized_queues : k => v if v.forward_to == null && v.forward_dead_lettered_messages_to == null }
  flatten_queue_rules = flatten([
    for queue_name, queue_params in local.normalized_queues : [
      for rule_key, rule_params in queue_params.authorization_rules : {
        queue_name  = queue_name
        rule_params = rule_params
        rule_name   = coalesce(rule_params.name, rule_key)
      }
    ]
  ])
  forward_queues = { for k, v in local.normalized_queues : k => v if v.forward_to != null || v.forward_dead_lettered_messages_to != null }
  normalized_queues = {
    for queue_key, queue_params in var.queues : coalesce(queue_params.name, queue_key) => queue_params
  }
  queue_rules = {
    for queue_rule in local.flatten_queue_rules :
    "${queue_rule.queue_name}|${queue_rule.rule_name}" => queue_rule
  }
}
