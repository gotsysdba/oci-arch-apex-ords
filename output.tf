# Copyright © 2020, Oracle and/or its affiliates. 
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output "lb_address" {
  value       = oci_load_balancer.lb.ip_address_details
  description = "The Pubic facing IP Address assigned to the Load Balancer"
}

output "ADMIN_Password" {
  value = "Please change the ADB ADMIN password manually in the OCI console for security"
}

// For debugging cloud-init only
//output "cloud-init" {
//  value = data.template_file.userdata.rendered
//}
