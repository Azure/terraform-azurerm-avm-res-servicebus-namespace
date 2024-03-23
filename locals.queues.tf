locals {
  flatten_queue_rules = flatten([
    for queue_name, queue_params in var.queues : [
      for rule_name, rule_params in queue_params.authorization_rules : {
        rule_name   = rule_name
        queue_name  = queue_name
        rule_params = rule_params
      }
    ]
  ])

  queue_rules = {
    for queue_rule in local.flatten_queue_rules :
    "${queue_rule.queue_name}|${queue_rule.rule_name}" => queue_rule
  }
}
