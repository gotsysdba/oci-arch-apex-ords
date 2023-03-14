# Copyright © 2020, Oracle and/or its affiliates. 
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

#####################################################################
## Depends on Paid Resource
#####################################################################
resource "oci_autoscaling_auto_scaling_configuration" "auto_scaling_configuration" {
  count          = local.is_scalable ? 1 : 0
  compartment_id = local.compartment_ocid
  display_name   = format("%s-auto-scaling-configuration", var.proj_abrv)
  auto_scaling_resources {
    id   = oci_core_instance_pool.instance_pool[0].id
    type = "instancePool"
  }
  policies {
    display_name = format("%s-auto-scaling-policy", var.proj_abrv)
    capacity {
      initial = var.compute_instances[local.sizing]
      min     = var.compute_instances[local.sizing]
      max     = var.compute_instances[local.sizing] * 3
    }
    policy_type = "threshold"
    rules {
      action {
        type  = "CHANGE_COUNT_BY"
        value = "1"
      }
      display_name = format("%s-auto-scaling-out-rule", var.proj_abrv)
      metric {
        metric_type = "CPU_UTILIZATION"
        threshold {
          operator = "GT"
          value    = "80"
        }
      }
    }
    rules {
      action {
        type  = "CHANGE_COUNT_BY"
        value = "-1"
      }
      display_name = format("%s-auto-scaling-out-rule", var.proj_abrv)
      metric {
        metric_type = "CPU_UTILIZATION"
        threshold {
          operator = "LT"
          value    = "20"
        }
      }
    }
  }
  cool_down_in_seconds = "300"
}