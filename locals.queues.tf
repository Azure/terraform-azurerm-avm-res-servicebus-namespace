locals {
  flatten_queue_rules = flatten([
    for queue_name, queue_params in var.queues : {
      for rule_name, rule_params in queue_params.authorization_rules : "${queue_name}|${rule_name}" => {
        rule_name  = rule_name
        queue_name = queue_name
        send       = rule_params.send
        listen     = rule_params.listen
        manage     = rule_params.manage
      }
    }
  ])

  queue_rules = { 
    for map_object in local.flatten_queue_rules : 
    keys(map_object)[0] => values(map_object)[0] 
    if length(keys(map_object)) > 0
  }
}
