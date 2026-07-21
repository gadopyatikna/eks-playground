resource "kubernetes_namespace_v1" "apps" {
  metadata {
    name = "apps"
  }
}

resource "kubernetes_deployment_v1" "client_webapp" {
  metadata {
    name      = "client-webapp"
    namespace = kubernetes_namespace_v1.apps.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "client-webapp"
    }
  }

  spec {
    replicas = var.client_webapp_replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "client-webapp"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "client-webapp"
        }
      }

      spec {
        container {
          name              = "client-web-api"
          image             = var.client_webapp_image
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = var.client_webapp_port
          }

          readiness_probe {
            http_get {
              path = "/ready"
              port = "http"
            }

            initial_delay_seconds = 3
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = "http"
            }

            initial_delay_seconds = 10
            period_seconds        = 20
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "client_webapp" {
  metadata {
    name      = "client-webapp"
    namespace = kubernetes_namespace_v1.apps.metadata[0].name
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "client-webapp"
    }

    port {
      name        = "http"
      port        = var.client_webapp_port
      target_port = "http"
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}
