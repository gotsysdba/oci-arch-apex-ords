# Copyright © 2023, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

#####################################################################
## Always Free + Paid Resources
#####################################################################
// Security Group for SSH
resource "oci_core_network_security_group" "security_group_ssh" {
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = format("%s-security-group-ssh", var.label_prefix)
}
// Security Group for SSH - EGRESS
resource "oci_core_network_security_group_security_rule" "security_group_ssh_egress" {
  network_security_group_id = oci_core_network_security_group.security_group_ssh.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}
// Security Group for SSH - INGRES
resource "oci_core_network_security_group_security_rule" "security_group_ssh_ingress_TCP22" {
  network_security_group_id = oci_core_network_security_group.security_group_ssh.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_subnet.subnet_public.cidr_block
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      max = 22
      min = 22
    }
  }
}

// Security Group for Load Balancer (lb)
resource "oci_core_network_security_group" "security_group_lb" {
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = format("%s-security-group-lb", var.label_prefix)
}
// Security Group for Load Balancer (lb) - EGRESS
resource "oci_core_network_security_group_security_rule" "security_group_lb_egress" {
  network_security_group_id = oci_core_network_security_group.security_group_lb.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}
// Security Group for Load Balancer (lb) - INGRESS
resource "oci_core_network_security_group_security_rule" "security_group_lb_ingress_TCP80" {
  network_security_group_id = oci_core_network_security_group.security_group_lb.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      max = 80
      min = 80
    }
  }
}
resource "oci_core_network_security_group_security_rule" "security_group_lb_ingress_TCP443" {
  network_security_group_id = oci_core_network_security_group.security_group_lb.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      max = 443
      min = 443
    }
  }
}

// Security Group for ORDS
resource "oci_core_network_security_group" "security_group_ords" {
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = format("%s-security-group-ords", var.label_prefix)
}
// Security Group for ORDS - EGRESS
resource "oci_core_network_security_group_security_rule" "security_group_ords_egress_grp" {
  network_security_group_id = oci_core_network_security_group.security_group_ords.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.security_group_ords.id
  destination_type          = "NETWORK_SECURITY_GROUP"
}
resource "oci_core_network_security_group_security_rule" "security_group_ords_egress" {
  network_security_group_id = oci_core_network_security_group.security_group_ords.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}
// Security Group for ORDS - INGRESS
resource "oci_core_network_security_group_security_rule" "security_group_ords_ingress_TCP8080" {
  network_security_group_id = oci_core_network_security_group.security_group_ords.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_subnet.subnet_public.cidr_block
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      max = 8080
      min = 8080
    }
  }
}

#####################################################################
## Paid Resources
#####################################################################
resource "oci_core_network_security_group" "security_group_adb" {
  count          = local.is_paid ? 1 : 0
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = format("%s-security-group-adb", var.label_prefix)
}

// Security Group for ADB - EGRESS
resource "oci_core_network_security_group_security_rule" "security_group_adb_egress" {
  count                     = local.is_paid ? 1 : 0
  network_security_group_id = oci_core_network_security_group.security_group_adb[0].id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_vcn.vcn.cidr_block
  destination_type          = "CIDR_BLOCK"
}
// Security Group for ADB - INGRESS
resource "oci_core_network_security_group_security_rule" "security_group_adb_ingress_TCP1522" {
  count                     = local.is_paid ? 1 : 0
  network_security_group_id = oci_core_network_security_group.security_group_adb[0].id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      max = 1522
      min = 1521
    }
  }
}