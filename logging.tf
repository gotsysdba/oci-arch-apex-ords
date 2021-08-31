# Copyright © 2020, Oracle and/or its affiliates. 
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_logging_log_group" "logging_log_group" {
  compartment_id = var.compartment_ocid
  display_name = format("%s-log-group", var.proj_abrv)
}

resource "oci_logging_log" "lb_error_log" {
  configuration {
    compartment_id = var.compartment_ocid
    source {
      category    = "error"
      resource    = oci_load_balancer.lb.id
      service     = "loadbalancer"
      source_type = "OCISERVICE"
    }
  }
  display_name = format("%s-lb-error", var.proj_abrv)
  freeform_tags = {
  }
  is_enabled         = "true"
  log_group_id       = oci_logging_log_group.logging_log_group.id
  log_type           = "SERVICE"
  retention_duration = "30"
}

resource "oci_logging_log" "lb_access_log" {
  configuration {
    compartment_id = var.compartment_ocid
    source {
      category    = "access"
      resource    = oci_load_balancer.lb.id
      service     = "loadbalancer"
      source_type = "OCISERVICE"
    }
  }
  display_name = format("%s-lb-access", var.proj_abrv)
  freeform_tags = {
  }
  is_enabled         = "true"
  log_group_id       = oci_logging_log_group.logging_log_group.id
  log_type           = "SERVICE"
  retention_duration = "30"
}