# Copyright © 2023, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

locals {
  compartment_ocid    = var.compartment_ocid != "" ? var.compartment_ocid : var.tenancy_ocid
  user_ocid           = var.user_ocid != "" ? var.user_ocid : var.current_user_ocid
  vcn_cidr            = format("10.%d.0.0/16", random_integer.cidr.result)
  subnet_public_cidr  = format("10.%d.1.0/24", random_integer.cidr.result)
  subnet_private_cidr = format("10.%d.2.0/24", random_integer.cidr.result)
}

locals {
  adb_ocid = oci_database_autonomous_database.autonomous_database.id
  ci_pubip = local.is_paid ? null : oci_core_instance.instance.public_ip
}

locals {
  sizing               = var.always_free ? "ALF" : var.size
  is_paid              = local.sizing != "ALF" ? true : false
  is_scalable          = local.sizing != "ALF" && local.sizing != "XS" ? true : false
  adb_private_endpoint = local.sizing != "ALF" ? true : false
  compute_shape        = local.sizing != "ALF" ? "VM.Standard.E4.Flex" : "VM.Standard.E2.1.Micro"
  is_flexible_shape    = length(regexall("Flex", local.compute_shape)) > 0 ? true : false
}

// If we have a value from limits, use that as ALF, otherwise use AD-1
locals {
  availability_domain = length(data.oci_limits_limit_values.limits_limit_values.limit_values.*.availability_domain) != 0 ? data.oci_limits_limit_values.limits_limit_values.limit_values[0].availability_domain : data.oci_identity_availability_domains.availability_domains.availability_domains[0]["name"]
}