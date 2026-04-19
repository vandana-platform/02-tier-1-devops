resource "kubernetes_namespace" "demo" {
  metadata {
    name = "hpa-demo"
  }

  depends_on = [aws_eks_node_group.this]
}

resource "kubernetes_deployment" "php_apache" {
  metadata {
    name      = "php-apache"
    namespace = kubernetes_namespace.demo.metadata[0].name
    labels    = { app = "php-apache" }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "php-apache" }
    }

    template {
      metadata {
        labels = { app = "php-apache" }
      }

      spec {
        container {
          name  = "php-apache"
          image = "registry.k8s.io/hpa-example"

          port {
            container_port = 80
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "php_apache" {
  metadata {
    name      = "php-apache"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }

  spec {
    selector = { app = "php-apache" }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "php_apache" {
  metadata {
    name      = "php-apache-hpa"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.php_apache.metadata[0].name
    }

    min_replicas = 1
    max_replicas = 5

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 50
        }
      }
    }
  }

  depends_on = [helm_release.metrics_server]
}
