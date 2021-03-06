# Copyright © 2020, Oracle and/or its affiliates. 
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

// Get the latest Oracle Linux image
data "oci_core_images" "images" {
  compartment_id           = local.compartment_ocid
  operating_system         = local.compute_image
  operating_system_version = var.linux_os_version
  shape                    = local.compute_shape

  filter {
    name   = "display_name"
    values = ["^.*Oracle[^G]*$"]
    regex  = true
  }
}

resource "oci_core_instance" "instance" {
  compartment_id      = local.compartment_ocid
  display_name        = format("%s-ords-core", var.proj_abrv)
  availability_domain = local.availability_domain
  shape               = local.compute_shape
  dynamic "shape_config" {
    for_each = local.is_flexible_shape ? [1] : []
    content {
      baseline_ocpu_utilization = "BASELINE_1_2"
      ocpus                     = var.compute_flex_shape_ocpus[local.sizing]
      // Memory OCPU * 16GB
      memory_in_gbs = var.compute_flex_shape_ocpus[local.sizing] * 16
    }
  }
  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.images.images[0].id
  }
  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false
    plugins_config {
      desired_state = "ENABLED"
      name          = "Bastion"
    }
  }
  // If this is ALF, we can't place in the private subnet as need access to the cloud agent/packages
  create_vnic_details {
    subnet_id        = local.is_paid ? oci_core_subnet.subnet_private[0].id : oci_core_subnet.subnet_public.id
    assign_public_ip = local.is_paid ? false : true
    nsg_ids          = [oci_core_network_security_group.security_group_ssh.id, oci_core_network_security_group.security_group_ords.id]
  }
  metadata = {
    ssh_authorized_keys = tls_private_key.example_com.public_key_openssh
    user_data = "${base64encode(
      templatefile("${path.root}/templates/cloud-config.tftpl",
        {
          db_password   = random_password.adb_password.result
          db_conn       = element([for i, v in oci_database_autonomous_database.autonomous_database.connection_strings[0].profiles : v.value if v.consumer_group == "TP" && v.tls_authentication == "SERVER"], 0)
          ords_version  = var.sotfware_ver["ords"]
          sqlcl_version = var.sotfware_ver["sqlcl"]
          jdk_version   = var.sotfware_ver["jdk-17"]
        }
      )
    )}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

#####################################################################
## Paid Resources (Mostly)
## To create the pool/scale need an image (paid)
#####################################################################
// Create an ORDS image from the core after ORDS is configured
resource "oci_core_image" "ords_instance_image" {
  count          = local.is_scalable ? 1 : 0
  compartment_id = local.compartment_ocid
  instance_id    = oci_core_instance.instance.id
}

resource "oci_core_instance_configuration" "instance_configuration" {
  count          = local.is_scalable ? 1 : 0
  compartment_id = local.compartment_ocid
  display_name   = format("%s-instance-configuration", var.proj_abrv)
  instance_details {
    instance_type = "compute"
    launch_details {
      compartment_id = local.compartment_ocid
      shape          = local.compute_shape
      dynamic "shape_config" {
        for_each = local.is_flexible_shape ? [1] : []
        content {
          baseline_ocpu_utilization = "BASELINE_1_2"
          ocpus                     = var.compute_flex_shape_ocpus[local.sizing]
          memory_in_gbs             = var.compute_flex_shape_ocpus[local.sizing] * 16
        }
      }
      source_details {
        source_type = "image"
        image_id    = oci_core_image.ords_instance_image[0].id
      }
      create_vnic_details {
        subnet_id        = oci_core_subnet.subnet_private[0].id
        assign_public_ip = false
        nsg_ids          = [oci_core_network_security_group.security_group_ssh.id, oci_core_network_security_group.security_group_ords.id]
      }
    }
  }
}

resource "oci_core_instance_pool" "instance_pool" {
  count                     = local.is_scalable ? 1 : 0
  compartment_id            = local.compartment_ocid
  instance_configuration_id = oci_core_instance_configuration.instance_configuration[0].id
  dynamic "placement_configurations" {
    for_each = data.oci_identity_availability_domains.availability_domains.availability_domains
    content {
      availability_domain = placement_configurations.value["name"]
      primary_subnet_id   = oci_core_subnet.subnet_private[0].id
    }
  }
  // Create without intances (the core added later); Auto-scaling will adjust
  size         = 0
  display_name = format("%s-ords-pool", var.proj_abrv)
  load_balancers {
    backend_set_name = oci_load_balancer_backend_set.lb_backend_set.name
    load_balancer_id = oci_load_balancer.lb.id
    port             = "8080"
    vnic_selection   = "PrimaryVnic"
  }
  lifecycle {
    // Don't readjust the size as will be pooled
    ignore_changes        = [size]
    create_before_destroy = true
  }
}

// Add the "core" instance into the pool
resource "oci_core_instance_pool_instance" "instance_pool_instance" {
  count            = local.is_scalable ? 1 : 0
  instance_id      = oci_core_instance.instance.id
  instance_pool_id = oci_core_instance_pool.instance_pool[0].id
}