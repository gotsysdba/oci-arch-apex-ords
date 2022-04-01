# Copyright © 2020, Oracle and/or its affiliates. 
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

#####################################################################
## Paid Resources
#####################################################################
resource "oci_data_safe_data_safe_private_endpoint" "data_safe_private_endpoint" {
  count          = local.is_always_free ? 0 : 1
  compartment_id = local.compartment_ocid
  display_name   = format("%s-data-safe-private-endpoint", var.proj_abrv)
  subnet_id      = oci_core_subnet.subnet_private[0].id
  vcn_id         = oci_core_vcn.vcn.id
  nsg_ids        = [oci_core_network_security_group.security_group_adb[0].id]
}

resource "oci_data_safe_target_database" "data_safe_target_database" {
  count          = local.is_always_free ? 0 : 1
  compartment_id = local.compartment_ocid
  display_name   = format("%s-data-safe-target-database", var.proj_abrv)
  database_details {
    database_type          = "AUTONOMOUS_DATABASE"
    infrastructure_type    = "ORACLE_CLOUD"
    autonomous_database_id = oci_database_autonomous_database.autonomous_database.id
  }

  connection_option {
    connection_type              = "PRIVATE_ENDPOINT"
    datasafe_private_endpoint_id = oci_data_safe_data_safe_private_endpoint.data_safe_private_endpoint[0].id
  }
}