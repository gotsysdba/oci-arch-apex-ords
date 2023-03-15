# Copyright © 2020, Oracle and/or its affiliates. 
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

// Basic Hidden
variable "tenancy_ocid" {}
variable "compartment_ocid" {
  default = ""
}
variable "region" {}

// Extra Hidden
variable "current_user_ocid" {
  default = ""
}
variable "fingerprint" {
  default = ""
}
variable "private_key_path" {
  default = ""
}

// General Configuration
variable "proj_abrv" {
  default = "apexpoc"
}
variable "size" {
  default = "ALF"
}
variable "adb_license_model" {
  default = "BRING_YOUR_OWN_LICENSE"
}
// Block APEX/ORDS Dev and Admin Tools 
variable "enable_lbaas_ruleset" {
  default = "false"
}

// ORDS Software Versions
variable "sotfware_ver" {
  type = map(any)
  default = {
    "jdk-17" = "2000:17.0.3.1-ga.x86_64"
    "ords"   = "22.2.0-6.el7"
    "sqlcl"  = "22.2.0-2.el7"
  }
}

// Additional Resources
variable "prov_object_storage" {
  description = "Provision Object Storage Bucket"
  default     = "false"
}

variable "prov_data_safe" {
  description = "Provision Data Safe"
  default     = "false"
}

variable "prov_oic" {
  description = "Provision Oracle Integration Cloud"
  default     = "false"
}

variable "enable_lb_logging" {
  description = "Enable Load Balancer Logging"
  default     = "false"
}

//The sizing is catering for schema.yaml visibility
//Default is ALF (size) though this boolean is false
//Check the locals at bottom for logic
variable "always_free" {
  default = "false"
}

variable "adb_cpu_core_count" {
  type = map(any)
  default = {
    "L"   = 4
    "M"   = 2
    "S"   = 1
    "XS"  = 1
    "ALF" = 1
  }
}

variable "adb_dataguard" {
  type = map(any)
  default = {
    "L"   = true
    "M"   = true
    "S"   = false
    "XS"  = false
    "ALF" = false
  }
}

variable "flex_lb_min_shape" {
  type = map(any)
  default = {
    "L"   = 100
    "M"   = 100
    "S"   = 10
    "XS"  = 10
    "ALF" = 10
  }
}

variable "flex_lb_max_shape" {
  type = map(any)
  default = {
    "L"   = 1250
    "M"   = 1250
    "S"   = 480
    "XS"  = 10
    "ALF" = 10
  }
}

// Number of ORDS Servers; Scalable x3 (excl. XS/ALF)
variable "compute_instances" {
  type = map(any)
  default = {
    "L"   = 3
    "M"   = 2
    "S"   = 1
    "XS"  = 1
    "ALF" = 1
  }
}

// Scalable x2 (excl. XS/ALF)
variable "compute_flex_shape_ocpus" {
  type = map(any)
  default = {
    "L"   = 4
    "M"   = 2
    "S"   = 1
    "XS"  = 1
    "ALF" = 1
  }
}

variable "adb_storage_size_in_tbs" {
  default = 1
}

variable "adb_db_version" {
  type = map(any)
  default = {
    "L"   = "19c"
    "M"   = "19c"
    "S"   = "19c"
    "XS"  = "19c"
    "ALF" = "21c"
  }
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
  default = true
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}

# Dynamic Locals
locals {
  sizing               = var.always_free ? "ALF" : var.size
  is_paid              = local.sizing != "ALF" ? true : false
  is_scalable          = local.sizing != "ALF" && local.sizing != "XS" ? true : false
  adb_private_endpoint = local.sizing != "ALF" ? true : false
  compute_image        = local.sizing != "ALF" ? "Oracle Autonomous Linux" : "Oracle Linux"
  compute_shape        = local.sizing != "ALF" ? "VM.Standard.E4.Flex" : "VM.Standard.E2.1.Micro"
  is_flexible_shape = length(regexall("Flex", local.compute_shape)) > 0 ? true : false
  compartment_ocid     = var.compartment_ocid != "" ? var.compartment_ocid : var.tenancy_ocid
}
