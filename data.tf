# Copyright © 2023, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "oci_identity_availability_domains" "availability_domains" {
  compartment_id = var.tenancy_ocid
}

// If this is ALF, need to determine which AD can create CI's in
data "oci_limits_limit_values" "limits_limit_values" {
  compartment_id = var.tenancy_ocid
  service_name   = "compute"
  scope_type     = "AD"
  name           = "vm-standard-e2-1-micro-count"
  filter {
    name   = "value"
    values = ["2"]
  }
}

data "oci_objectstorage_namespace" "ns" {
  compartment_id = local.compartment_ocid
}

data "oci_core_images" "images" {
  compartment_id           = local.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = var.linux_os_version
  shape                    = local.compute_shape
  filter {
    name   = "display_name"
    values = ["^.*Oracle[^G]*$"]
    regex  = true
  }
}

data "template_file" "user_data" {
  count    = var.debug_cloudinit ? 1 : 0
  template = file("${path.root}/templates/cloud-config.tftpl")
  vars = {
    db_password = random_password.adb_password.result
    db_conn     = element([for i, v in oci_database_autonomous_database.autonomous_database.connection_strings[0].profiles : v.value if v.consumer_group == "TP" && v.tls_authentication == "SERVER"], 0)
  }
}