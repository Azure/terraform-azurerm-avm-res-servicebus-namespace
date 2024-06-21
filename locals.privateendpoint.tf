locals {
  normalized_private_endpoints = var.sku == local.premium_sku_name ? var.private_endpoints : {}
  private_endpoint_application_security_group_associations = var.sku == local.premium_sku_name ? {
    for assoc in flatten([
      for pe_k, pe_v in var.private_endpoints : [
        for asg_k, asg_v in pe_v.application_security_group_associations : {
          asg_key         = asg_k
          pe_key          = pe_k
          asg_resource_id = asg_v
        }
      ]
    ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc
  } : {}
  service_name = "namespace"
}