# Copyright © 2020, Oracle and/or its affiliates. 
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "region" {}
variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "ssh_private_key" {}
variable "ssh_public_key" {}


// Project Specifics
variable "proj_abrv" {
  default = "apexpoc"
}

variable "adb_license_model" {
  default = "BRING_YOUR_OWN_LICENSE"
}

// Sizing
variable "size" {
    default = "ALF"
}

variable "adb_cpu_core_count" {
  type = map
  default = {
    "XL"  = 4
    "L"   = 4
    "M"   = 2
    "S"   = 1
    "ALF" = 1
  }
}

variable "adb_dataguard" {
  type = map
  default = {
    "XL"  = true
    "L"   = true
    "M"   = true
    "S"   = false
    "ALF" = false
  }
}

variable "flex_lb_min_shape" {
  type = map
  default = {
    "XL"  = 100
    "L"   = 100
    "M"   = 100
    "S"   = 10
    "ALF" = 10
  }
}

variable "flex_lb_max_shape" {
  type = map
  default = {
    "XL"  = 4990
    "L"   = 4990
    "M"   = 4990
    "S"   = 480
    "ALF" = 10
  }
}

// Number of ORDS Servers; Scalable x3 (excl. ALF)
variable "compute_instances" {
  type = map
  default = {
    "XL"  = 3
    "L"   = 3
    "M"   = 2
    "S"   = 1
    "ALF" = 1
  }
}

variable "compute_flex_shape_ocpus" {
  type = map
  default = {
    "XL"  = 4
    "L"   = 4
    "M"   = 2
    "S"   = 1
    "ALF" = 1
  }
}

variable "adb_storage_size_in_tbs" {
  default = 1
}

variable "adb_db_version" {
  default = "19c"
}

variable "compute_os" {
  default = "Oracle Autonomous Linux"
}

variable "linux_os_version" {
  default = "7.9"
}

variable "bastion_user" {
  default = "opc"
}

// VCN Configurations Variables
variable "vcn_cidr" {
  default = "10.0.0.0/16"
}

variable "vcn_is_ipv6enabled" {
  default = false
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}

# Dictionary Locals
locals {
  compute_flexible_shapes = [
    "VM.Standard.E3.Flex",
    "VM.Standard.E4.Flex",
    "VM.Standard.A1.Flex",
    "VM.Optimized3.Flex"
  ]
}

# Dynamic Vars
locals {
  is_always_free       = var.size != "ALF" ? false : true
  adb_private_endpoint = var.size != "ALF" ? true  : false
  compute_shape        = var.size != "ALF" ? "VM.Standard.E3.Flex" : "VM.Standard.E2.1.Micro"
  is_flexible_shape    = contains(local.compute_flexible_shapes, local.compute_shape)
}