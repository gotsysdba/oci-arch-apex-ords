# Copyright © 2020, Oracle and/or its affiliates. 
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_bastion_bastion" "bastion_service" {
  compartment_id               = var.compartment_ocid
  bastion_type                 = "STANDARD"
  target_subnet_id             = oci_core_subnet.subnet_public.id
  client_cidr_block_allow_list = ["0.0.0.0/0"]
  name                         = format("%sBastionService", var.proj_abrv)
  max_session_ttl_in_seconds   = 10800
}