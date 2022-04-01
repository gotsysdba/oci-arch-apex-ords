# Copyright © 2020, Oracle and/or its affiliates. 
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "oci_objectstorage_namespace" "ns" {
  compartment_id = local.compartment_ocid
}

resource "oci_objectstorage_bucket" "bucket" {
  count          = var.prov_object_storage ? 1 : 0
  compartment_id = local.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = format("%s-bucket", var.proj_abrv)
  access_type    = "NoPublicAccess"
  auto_tiering   = "Disabled"
}