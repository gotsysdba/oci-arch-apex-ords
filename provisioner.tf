locals {
  adb_ocid = oci_database_autonomous_database.autonomous_database.id
  ci_pubip = oci_core_instance.instance.public_ip
}

resource "null_resource" "oci_whitelist" {
  count = local.is_always_free ? 1 : 0
  triggers = {
    ci_public_ip = oci_core_instance.instance.public_ip
  }
  provisioner "local-exec" {    
    command = "oci db autonomous-database update --autonomous-database-id ${local.adb_ocid} --whitelisted-ips '[\"${local.ci_pubip}\"]' --force"
    environment = {
      OCI_CLI_USER         = var.user_ocid
      OCI_CLI_REGION       = var.region
      OCI_CLI_TENANCY      = var.tenancy_ocid
      OCI_CLI_FINGERPRINT  = var.fingerprint != "" ? var.fingerprint : null
      OCI_CLI_KEY_FILE     = var.private_key_path != "" ? var.private_key_path : null
    }  
  }
}
