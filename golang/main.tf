variable "external_ip" {}
variable "node_port" {}
variable "project_id" {}

resource "kubernetes_service" "default" {
  metadata {
    namespace = "default"
    name      = "morse-socket"
  }

  spec {
    type             = "NodePort"
    session_affinity = "ClientIP"
    external_ips     = ["${var.external_ip}"]

    selector {
      run = "morse-socket"
    }

    port {
      name        = "tcp"
      protocol    = "TCP"
      port        = 110
      target_port = 5000
      node_port   = "${var.node_port}"
    }
  }
}

resource "kubernetes_config_map" "default" {
  metadata {
    name = "morse-socket"
  }
}

resource "kubernetes_replication_controller" "default" {
  metadata {
    name      = "morse-socket"
    namespace = "default"

    labels {
      run = "morse-socket"
    }
  }

  spec {
    selector {
      run = "morse-socket"
    }

    template {
      container {
        image = "gcr.io/${var.project_id}/morse-socket:latest"
        name  = "morse-socket"

        resources {
          limits {
            cpu    = "0.5"
            memory = "512Mi"
          }

          requests {
            cpu    = "250m"
            memory = "50Mi"
          }
        }
      }

        
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "default" {
  metadata {
    name = "morse-socket"
  }
  spec {
    max_replicas = 10
    min_replicas = 2
    scale_target_ref {
      kind = "ReplicationController"
      name = "morse-socket"
    }
  }
}



