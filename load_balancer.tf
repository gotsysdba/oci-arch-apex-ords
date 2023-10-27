# Copyright © 2023, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_load_balancer" "lb" {
  compartment_id = local.compartment_ocid
  display_name   = format("%s-lb", var.label_prefix)
  shape          = "flexible"
  is_private     = false
  shape_details {
    minimum_bandwidth_in_mbps = var.flex_lb_min_shape[local.sizing]
    maximum_bandwidth_in_mbps = var.flex_lb_max_shape[local.sizing]
  }
  subnet_ids = [
    oci_core_subnet.subnet_public.id
  ]
  network_security_group_ids = [oci_core_network_security_group.security_group_lb.id]
}

resource "oci_load_balancer_backend_set" "lb_backend_set" {
  load_balancer_id = oci_load_balancer.lb.id
  name             = format("%s-lb-backend-set", var.label_prefix)
  policy           = "LEAST_CONNECTIONS"
  session_persistence_configuration {
    cookie_name = "*"
  }
  health_checker {
    interval_ms         = "10000"
    port                = "8080"
    protocol            = "HTTP"
    response_body_regex = ""
    retries             = "3"
    return_code         = "200"
    timeout_in_millis   = "3000"
    url_path            = "/favicon.ico"
  }
}

resource "oci_load_balancer_listener" "lb_listener_80" {
  load_balancer_id         = oci_load_balancer.lb.id
  name                     = format("%s-lb-listener-80", var.label_prefix)
  default_backend_set_name = oci_load_balancer_backend_set.lb_backend_set.name
  port                     = 80
  protocol                 = "HTTP"
  rule_set_names           = var.enable_lbaas_ruleset ? [oci_load_balancer_rule_set.lb_rule_set.name] : []
}

// Ignore changes to avoid overwriting valid certs loaded in later
resource "oci_load_balancer_listener" "lb_listener_443" {
  load_balancer_id         = oci_load_balancer.lb.id
  name                     = format("%s-lb-listener-443", var.label_prefix)
  default_backend_set_name = oci_load_balancer_backend_set.lb_backend_set.name
  port                     = 443
  protocol                 = "HTTP"
  rule_set_names           = var.enable_lbaas_ruleset ? [oci_load_balancer_rule_set.lb_rule_set.name] : []
  ssl_configuration {
    certificate_name        = oci_load_balancer_certificate.lb_certificate.certificate_name
    verify_peer_certificate = false
  }
  lifecycle {
    ignore_changes = [ssl_configuration[0].certificate_name]
  }
}

resource "oci_load_balancer_certificate" "lb_certificate" {
  certificate_name = "get_a_real_cert"
  load_balancer_id = oci_load_balancer.lb.id

  ca_certificate     = tls_self_signed_cert.acme_ca.cert_pem
  public_certificate = tls_locally_signed_cert.example_com.cert_pem
  private_key        = tls_private_key.example_com.private_key_pem

  lifecycle {
    create_before_destroy = true
  }
}

resource "oci_load_balancer_rule_set" "lb_rule_set" {
  load_balancer_id = oci_load_balancer.lb.id
  name             = "APEX_Public_Access"
  items {
    action = "ADD_HTTP_REQUEST_HEADER"
    header = "APEX-Public-Access"
    value  = "1"
  }
  items {
    action = "REDIRECT"
    conditions {
      attribute_name  = "PATH"
      attribute_value = "/sql-developer"
      operator        = "SUFFIX_MATCH"
    }
    redirect_uri {
      host     = "apex.oracle.com"
      path     = "/"
      protocol = "https"
      query    = ""
    }
    response_code = "301"
  }
  items {
    action = "REDIRECT"
    conditions {
      attribute_name  = "PATH"
      attribute_value = "/sign-in/"
      operator        = "SUFFIX_MATCH"
    }
    redirect_uri {
      host     = "apex.oracle.com"
      path     = "/"
      protocol = "https"
      query    = ""
    }
    response_code = "301"
  }
  items {
    action = "REDIRECT"
    conditions {
      attribute_name  = "PATH"
      attribute_value = "/signed-out/"
      operator        = "SUFFIX_MATCH"
    }
    redirect_uri {
      host     = "apex.oracle.com"
      path     = "/"
      protocol = "https"
      query    = ""
    }
    response_code = "301"
  }
  items {
    action = "REDIRECT"
    conditions {
      attribute_name  = "PATH"
      attribute_value = "/sign-in/session"
      operator        = "SUFFIX_MATCH"
    }
    redirect_uri {
      host     = "apex.oracle.com"
      path     = "/"
      protocol = "https"
      query    = ""
    }
    response_code = "301"
  }
  items {
    action = "REDIRECT"
    conditions {
      attribute_name  = "PATH"
      attribute_value = "/_/sql"
      operator        = "SUFFIX_MATCH"
    }
    redirect_uri {
      host     = "apex.oracle.com"
      path     = "/"
      protocol = "https"
      query    = ""
    }
    response_code = "301"
  }
  items {
    action = "REDIRECT"
    conditions {
      attribute_name  = "PATH"
      attribute_value = "/ords/_/db-api/"
      operator        = "PREFIX_MATCH"
    }
    redirect_uri {
      host     = "apex.oracle.com"
      path     = "/"
      protocol = "https"
      query    = ""
    }
    response_code = "301"
  }
  items {
    action = "REDIRECT"
    conditions {
      attribute_name  = "PATH"
      attribute_value = "/_/public-properties/"
      operator        = "SUFFIX_MATCH"
    }
    redirect_uri {
      host     = "apex.oracle.com"
      path     = "/"
      protocol = "https"
      query    = ""
    }
    response_code = "301"
  }
}

// Add Instance to LBaaS if not part of the Pool
resource "oci_load_balancer_backend" "lb_backend" {
  count            = local.is_scalable ? 0 : 1
  load_balancer_id = oci_load_balancer.lb.id
  backendset_name  = oci_load_balancer_backend_set.lb_backend_set.name
  ip_address       = oci_core_instance.instance.private_ip
  port             = 8080
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}