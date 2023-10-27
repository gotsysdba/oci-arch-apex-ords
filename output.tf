# Copyright © 2023, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output "lb_address" {
  value       = format("https://%s", oci_load_balancer.lb.ip_address_details[0].ip_address)
  description = "The Pubic facing IP Address assigned to the Load Balancer"
}

output "ADMIN_Password" {
  value = "Please change the ADB ADMIN password manually in the OCI console for security"
}

output "Patience" {
  value = "After Deployment, Please have patience (5-10min) as the Customer Managed ORDS configures itself"
}

// For debugging cloud-init only
output "cloud-init" {
  value = var.debug_cloudinit ? data.template_file.user_data[0].rendered : null
}
