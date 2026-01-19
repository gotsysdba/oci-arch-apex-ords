# Copyright © 2023, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "random_password" "adb_password" {
  length           = 16
  min_numeric      = 1
  min_lower        = 1
  min_upper        = 1
  min_special      = 1
  override_special = "_#[]"
  keepers = {
    uuid = "uuid()"
  }
}

resource "oci_database_autonomous_database" "autonomous_database" {
  admin_password                       = random_password.adb_password.result
  autonomous_maintenance_schedule_type = "REGULAR"
  character_set                        = "AL32UTF8"
  compartment_id                       = local.compartment_ocid
  compute_count                        = var.adb_cpu_core_count[local.sizing]
  compute_model                        = "ECPU"
  data_storage_size_in_gb              = var.adb_data_storage_size_in_gb
  db_name                              = format("%sDB", upper(var.label_prefix))
  db_version                           = var.adb_db_version[local.sizing]
  db_workload                          = "OLTP"
  display_name                         = format("%sDB", upper(var.label_prefix))
  is_free_tier                         = false
  is_auto_scaling_enabled              = local.is_scalable
  is_auto_scaling_for_storage_enabled  = local.is_scalable
  is_dedicated                         = false
  license_model                        = local.is_paid ? var.adb_license_model : "LICENSE_INCLUDED"
  is_mtls_connection_required          = true
  nsg_ids                              = local.adb_private_endpoint ? [oci_core_network_security_group.security_group_adb[0].id] : null
  whitelisted_ips                      = local.is_paid ? null : [oci_core_vcn.vcn.id]
  private_endpoint_label               = local.adb_private_endpoint ? lower(var.label_prefix) : null
  subnet_id                            = local.adb_private_endpoint ? oci_core_subnet.subnet_private[0].id : null
  lifecycle {
    // cannot change from PRIVATE_ENDPOINT_ACCESS to SECURE_ACCESS
    ignore_changes = [whitelisted_ips, private_endpoint_label, subnet_id]
  }
}