terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}
provider "kubernetes" {
  config_path = "~/.kube/config"
}
resource "kubernetes_namespace" "apps" {
  metadata {
    name = "apps"
  }
}
resource "kubernetes_deployment" "blue-app" {
  metadata {
    name      = "blue-app"
    namespace = kubernetes_namespace.apps.metadata.0.name
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "blue-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "blue-app"
        }
      }
      spec {
        container {
          image = "hashicorp/http-echo"
          name  = "http-echo"
          args  = ["-listen=:8080", "-text='I am green'"]
          port {
            container_port = 8080
          }
        }
      }
    }
  }
}
resource "kubernetes_deployment" "green-app" {
  metadata {
    name      = "green-app"
    namespace = kubernetes_namespace.apps.metadata.0.name
  }
  spec {
    replicas = 3
    selector {
      match_labels = {
        app = "green-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "green-app"
        }
      }
      spec {
        container {
          image = "hashicorp/http-echo"
          name  = "http-echo"
          args  = ["-listen=:8081", "-text='I am green'"]
          port {
            container_port = 8081
          }
        }
      }
    }
  }
}
resource "kubernetes_service" "blue-app" {
  metadata {
    name      = "blue-app"
    namespace = kubernetes_namespace.apps.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.blue-app.spec.0.template.0.metadata.0.labels.app
    }
    port {
      port        = 8080
      target_port = 8081
    }
  }
}
resource "kubernetes_service" "green-app" {
  metadata {
    name      = "green-app"
    namespace = kubernetes_namespace.apps.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.green-app.spec.0.template.0.metadata.0.labels.app
    }
    port {
      port        = 8081
      target_port = 8080
    }
  }
}
resource "kubernetes_ingress_class" "example" {
  metadata {
    name = "example"
  }

  spec {
    controller = "example.com/ingress-controller"
    parameters {
      api_group = "k8s.example.com"
      kind      = "IngressParameters"
      name      = "external-lb"
      traffic_weight = 25
    }
  }
}

