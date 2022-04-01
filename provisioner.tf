# Copyright © 2020, Oracle and/or its affiliates. 
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

locals {
  adb_ocid = oci_database_autonomous_database.autonomous_database.id
  ci_pubip = oci_core_instance.instance.public_ip
}

// Avoid Circular Logic for ALF only; requires OCI CLI to update the Whitelist of the ADB post prov'ing of Compute
resource "null_resource" "oci_whitelist" {
  count = local.is_paid ? 0 : 1
  triggers = {
    ci_public_ip = oci_core_instance.instance.public_ip
  }
  provisioner "local-exec" {    
    command = "oci db autonomous-database update --autonomous-database-id ${local.adb_ocid} --whitelisted-ips '[\"${local.ci_pubip}\"]' --force"
    environment = {
      OCI_CLI_USER         = var.current_user_ocid
      OCI_CLI_REGION       = var.region
      OCI_CLI_TENANCY      = var.tenancy_ocid
      OCI_CLI_FINGERPRINT  = var.fingerprint != "" ? var.fingerprint : null
      OCI_CLI_KEY_FILE     = var.private_key_path != "" ? var.private_key_path : null
    }  
  }
}
