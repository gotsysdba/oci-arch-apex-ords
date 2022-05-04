# Copyright © 2020, Oracle and/or its affiliates. 
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
data template_file "userdata" {
  template = file("${path.module}/templates/ords-cloud-config.yaml")

  vars = {
    db_password   = random_password.autonomous_database_password.result
    db_conn       = element([for i, v in oci_database_autonomous_database.autonomous_database.connection_strings[0].profiles : 
                        v.value if v.consumer_group == "TP" && v.tls_authentication == "SERVER"],0)
  }
}