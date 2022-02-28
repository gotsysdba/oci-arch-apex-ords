# Copyright © 2020, Oracle and/or its affiliates. 
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

#####################################################################
## Paid Resource
#####################################################################
resource "oci_integration_integration_instance" "integration_instance" {
  count                     = local.is_always_free ? 0 : var.enable_integration_service
  compartment_id            = var.compartment_ocid
  display_name              = format("%s-auto-integration_instance", var.proj_abrv)
  consumption_model         = "UCM"
  integration_instance_type = "STANDARD"
  is_byol                   = "true"
  is_file_server_enabled    = "false"
  is_visual_builder_enabled = "true"
  message_packs             = "1"
}
