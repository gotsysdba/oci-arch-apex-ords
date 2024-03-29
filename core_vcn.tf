# Copyright © 2023, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_vcn" "vcn" {
  compartment_id = local.compartment_ocid
  display_name   = format("%s-vcn", var.label_prefix)
  cidr_block     = local.vcn_cidr
  is_ipv6enabled = var.vcn_is_ipv6enabled
  dns_label      = var.label_prefix
}

// Catch-22 for Always Free; Need to have ORDS in public with public
// to get the agent for bastion; so restrict SSH to only the public cidr
resource "oci_core_default_security_list" "export_Default-Security-List-for-apexpoc-vcn" {
  compartment_id = local.compartment_ocid
  display_name   = "Default Security List"
  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = "false"
  }
  ingress_security_rules {
    protocol    = "6"
    source      = oci_core_subnet.subnet_public.cidr_block
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    icmp_options {
      code = "-1"
      type = "3"
    }
    protocol    = "1"
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  manage_default_resource_id = oci_core_vcn.vcn.default_security_list_id
}

#####################################################################
## Always Free + Paid Resources
#####################################################################
resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = format("%s-internet-gateway", var.label_prefix)
}

resource "oci_core_route_table" "route_table_internet_gw" {
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = format("%s-route-table-internet-gw", var.label_prefix)
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
}

resource "oci_core_subnet" "subnet_public" {
  compartment_id             = local.compartment_ocid
  vcn_id                     = oci_core_vcn.vcn.id
  display_name               = format("%s-subnet-public", var.label_prefix)
  cidr_block                 = local.subnet_public_cidr
  route_table_id             = oci_core_route_table.route_table_internet_gw.id
  dhcp_options_id            = oci_core_vcn.vcn.default_dhcp_options_id
  dns_label                  = "publ"
  prohibit_public_ip_on_vnic = false
}

#####################################################################
## Paid Resources
#####################################################################
resource "oci_core_nat_gateway" "nat_gateway" {
  count          = local.is_paid ? 1 : 0
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = format("%s-nat-gateway", var.label_prefix)
}

resource "oci_core_route_table" "route_table_nat_gw" {
  count          = local.is_paid ? 1 : 0
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = format("%s-route-table-nat-gw", var.label_prefix)
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gateway[count.index].id
  }
}

resource "oci_core_subnet" "subnet_private" {
  count                      = local.is_paid ? 1 : 0
  compartment_id             = local.compartment_ocid
  vcn_id                     = oci_core_vcn.vcn.id
  display_name               = format("%s-subnet-private", var.label_prefix)
  cidr_block                 = local.subnet_private_cidr
  route_table_id             = oci_core_route_table.route_table_nat_gw[0].id
  dhcp_options_id            = oci_core_vcn.vcn.default_dhcp_options_id
  dns_label                  = "priv"
  prohibit_public_ip_on_vnic = true
  // This is to prevent the attempt to destroy the NSG before the subnet (VNIC attachment)
  depends_on = [
    oci_core_network_security_group.security_group_adb
  ]
}