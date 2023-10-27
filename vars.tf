# Copyright © 2023, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "tenancy_ocid" {
  description = "The Tenancy ID of the OCI Cloud Account in which to create the resources."
  type        = string
}

variable "compartment_ocid" {
  description = "The Compartment ID where to create all resources."
  type        = string
}

variable "region" {
  description = "The OCI Region where resources will be created."
  type        = string
}

variable "user_ocid" {
  description = "The ID of the User that terraform will use to create the resources."
  type        = string
  default     = ""
}

variable "current_user_ocid" {
  description = "The ID of the user that terraform will use to create the resources. ORM compatible"
  type        = string
  default     = ""
}

variable "fingerprint" {
  description = "Fingerprint of the API private key to use with OCI API."
  type        = string
  default     = ""
}

variable "private_key" {
  description = "The contents of the private key file to use with OCI API. This takes precedence over private_key_path if both are specified in the provider."
  sensitive   = true
  type        = string
  default     = ""
}

variable "private_key_path" {
  description = "The path to the OCI API private key."
  type        = string
  default     = ""
}

// General Configuration
variable "label_prefix" {
  description = "A string that will be prepended to all resources."
  type        = string
  default     = "apexpoc"
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
  default = "8"
}

variable "bastion_user" {
  default = "opc"
}

// VCN Configurations Variables
variable "vcn_is_ipv6enabled" {
  default = false
}

// Debug CloudInit
variable "debug_cloudinit" {
  default = false
}