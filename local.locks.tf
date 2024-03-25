locals {
  pe_locks = {
    for pe_name, pe_params in local.normalized_private_endpoints :
    "PrivateEndpoint|${pe_name}" => {
      scope_type = "PrivateEndpoint"
      pe_name    = pe_name
      lock       = pe_params.lock.kind == "Inherit" ? var.lock : pe_params.lock
    }
  }

  filtered_pe_locks = {
    for k, v in local.pe_locks :
    k => v
    if try(v.lock.kind, "None") != "None"
  }

  namespace_lock = var.lock != null ? {
    "Namespace" = {
      scope_type = "Namespace"
      lock       = var.lock
    }
  } : {}

  total_locks = merge(local.filtered_pe_locks, local.namespace_lock)
}
