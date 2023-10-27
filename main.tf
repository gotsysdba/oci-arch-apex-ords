# Copyright © 2023, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "random_integer" "cidr" {
  // Leave a few at the end to get the subnet CIDRS (+1 and +2 respectively)
  min = 1
  max = 250
}

resource "oci_bastion_bastion" "bastion_service" {
  compartment_id               = local.compartment_ocid
  bastion_type                 = "STANDARD"
  target_subnet_id             = oci_core_subnet.subnet_public.id
  client_cidr_block_allow_list = ["0.0.0.0/0"]
  name                         = format("%sBastionService", var.label_prefix)
  max_session_ttl_in_seconds   = 10800
}

resource "oci_objectstorage_bucket" "bucket" {
  count          = var.prov_object_storage ? 1 : 0
  compartment_id = local.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = format("%s-bucket", var.label_prefix)
  access_type    = "NoPublicAccess"
  auto_tiering   = "Disabled"
}