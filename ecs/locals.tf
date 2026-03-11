locals {
  # Service catalog — single source of truth for all ECS services
  services = {
    # Auth Domain
    "gateway-service" = {
      dockerfile_path   = "domain/auth/gateway-service/Dockerfile"
      container_port    = 8443
      cpu               = 512
      memory            = 1024
      desired_count     = 2
      enable_alb        = true
      health_check_path = "/actuator/health"
      task_role         = "auth"
      environment = {
        SPRING_PROFILES_ACTIVE = "ecs"
        TZ                     = "Asia/Seoul"
      }
    }
    "user-command-service" = {
      dockerfile_path   = "domain/auth/user-command-service/Dockerfile"
      container_port    = 8086
      cpu               = 256
      memory            = 512
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "auth"
      environment = {
        SPRING_PROFILES_ACTIVE = "ecs"
        TZ                     = "Asia/Seoul"
      }
    }
    "email-service" = {
      dockerfile_path   = "domain/auth/email-service/Dockerfile"
      container_port    = 8085
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        SPRING_PROFILES_ACTIVE = "ecs"
        TZ                     = "Asia/Seoul"
      }
    }
    "user-write-service" = {
      dockerfile_path   = "data/auth/user-write-service/Dockerfile"
      container_port    = 8188
      grpc_port         = 9188
      cpu               = 256
      memory            = 512
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        TZ = "Asia/Seoul"
      }
    }
    "user-read-service" = {
      dockerfile_path   = "data/auth/user-read-service/Dockerfile"
      container_port    = 8189
      grpc_port         = 9189
      cpu               = 256
      memory            = 512
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "auth"
      environment = {
        TZ = "Asia/Seoul"
      }
    }
    # Products Domain
    "products-create-service" = {
      dockerfile_path   = "domain/products/products-create-service/Dockerfile"
      container_port    = 8080
      cpu               = 256
      memory            = 512
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        SPRING_PROFILES_ACTIVE = "ecs"
        TZ                     = "Asia/Seoul"
      }
    }
    "products-list-service" = {
      dockerfile_path   = "domain/products/products-list-service/Dockerfile"
      container_port    = 8080
      cpu               = 256
      memory            = 512
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        SPRING_PROFILES_ACTIVE = "ecs"
        TZ                     = "Asia/Seoul"
      }
    }
    "products-write-service" = {
      dockerfile_path   = "data/products/products-write-service/Dockerfile"
      container_port    = 8116
      cpu               = 256
      memory            = 512
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        TZ = "Asia/Seoul"
      }
    }
    "products-read-service" = {
      dockerfile_path   = "data/products/products-read-service/Dockerfile"
      container_port    = 8115
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        TZ = "Asia/Seoul"
      }
    }
    "cancellation-policy-data" = {
      dockerfile_path   = "data/products/cancellation-policy-data/Dockerfile"
      container_port    = 8114
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        TZ = "Asia/Seoul"
      }
    }
    # Reviews Domain
    "reviews-create-service" = {
      dockerfile_path   = "domain/reviews/reviews-create-service/Dockerfile"
      container_port    = 8080
      cpu               = 256
      memory            = 512
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        TZ = "Asia/Seoul"
      }
    }
    "reviews-list-service" = {
      dockerfile_path   = "domain/reviews/reviews-list-service/Dockerfile"
      container_port    = 8080
      cpu               = 256
      memory            = 512
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        TZ = "Asia/Seoul"
      }
    }
    "review-write-service" = {
      dockerfile_path   = "data/reviews/review-write-service/Dockerfile"
      container_port    = 8130
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        TZ = "Asia/Seoul"
      }
    }
    "review-read-service" = {
      dockerfile_path   = "data/reviews/review-read-service/Dockerfile"
      container_port    = 8131
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        TZ = "Asia/Seoul"
      }
    }
    # Wishlists
    "wishlist-data" = {
      dockerfile_path   = "data/wishlists/wishlist-data/Dockerfile"
      container_port    = 8140
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        TZ = "Asia/Seoul"
      }
    }
    # SKUs
    "skus-write-service" = {
      dockerfile_path   = "data/skus/skus-write-service/Dockerfile"
      container_port    = 8091
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        SPRING_PROFILES_ACTIVE = "ecs"
        TZ                     = "Asia/Seoul"
      }
    }
    "skus-read-service" = {
      dockerfile_path   = "data/skus/skus-read-service/Dockerfile"
      container_port    = 8092
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        SPRING_PROFILES_ACTIVE = "ecs"
        TZ                     = "Asia/Seoul"
      }
    }
    "sku-flights-write-service" = {
      dockerfile_path   = "data/sku-flights/sku-flights-write-service/Dockerfile"
      container_port    = 8202
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        SPRING_PROFILES_ACTIVE = "ecs"
        TZ                     = "Asia/Seoul"
      }
    }
    "sku-flights-read-service" = {
      dockerfile_path   = "data/sku-flights/sku-flights-read-service/Dockerfile"
      container_port    = 8203
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        SPRING_PROFILES_ACTIVE = "ecs"
        TZ                     = "Asia/Seoul"
      }
    }
    # Booking Domain
    "reservation-travel-service" = {
      dockerfile_path   = "domain/booking/reservation-travel-service/Dockerfile"
      container_port    = 8210
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        TZ = "Asia/Seoul"
      }
    }
    "publish-order-service" = {
      dockerfile_path   = "domain/booking/publish-order-service/Dockerfile"
      container_port    = 8211
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        TZ = "Asia/Seoul"
      }
    }
    "save-payments-service" = {
      dockerfile_path   = "domain/booking/save-payments-service/Dockerfile"
      container_port    = 8212
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        TZ = "Asia/Seoul"
      }
    }
    # Orders Data
    "orders-write-service" = {
      dockerfile_path   = "data/orders/orders-write-service/Dockerfile"
      container_port    = 8204
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "booking"
      environment = {
        TZ = "Asia/Seoul"
      }
    }
    "orders-read-service" = {
      dockerfile_path   = "data/orders/orders-read-service/Dockerfile"
      container_port    = 8205
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "booking"
      environment = {
        TZ = "Asia/Seoul"
      }
    }
    # Payments Data
    "payments-write-service" = {
      dockerfile_path   = "data/payments/payments-write-service/Dockerfile"
      container_port    = 8206
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        SPRING_PROFILES_ACTIVE = "ecs"
        TZ                     = "Asia/Seoul"
      }
    }
    "payments-read-service" = {
      dockerfile_path   = "data/payments/payments-read-service/Dockerfile"
      container_port    = 8207
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        SPRING_PROFILES_ACTIVE = "ecs"
        TZ                     = "Asia/Seoul"
      }
    }
    # Order Items Data
    "order-items-write-service" = {
      dockerfile_path   = "data/order-items/order-items-write-service/Dockerfile"
      container_port    = 8208
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        SPRING_PROFILES_ACTIVE = "ecs"
        TZ                     = "Asia/Seoul"
      }
    }
    "order-items-read-service" = {
      dockerfile_path   = "data/order-items/order-items-read-service/Dockerfile"
      container_port    = 8209
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        SPRING_PROFILES_ACTIVE = "ecs"
        TZ                     = "Asia/Seoul"
      }
    }
    # Location Data
    "location-write-service" = {
      dockerfile_path   = "data/location/location-write-service/Dockerfile"
      container_port    = 8213
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        SPRING_PROFILES_ACTIVE = "ecs"
        TZ                     = "Asia/Seoul"
      }
    }
    "location-read-service" = {
      dockerfile_path   = "data/location/location-read-service/Dockerfile"
      container_port    = 8214
      cpu               = 256
      memory            = 256
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/actuator/health"
      task_role         = "default"
      environment = {
        SPRING_PROFILES_ACTIVE = "ecs"
        TZ                     = "Asia/Seoul"
      }
    }
    # Travel AI (FastAPI)
    "travel-ai" = {
      dockerfile_path   = "lambda/travel-ai/Dockerfile"
      container_port    = 8000
      cpu               = 512
      memory            = 1024
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/health"
      task_role         = "travel-ai"
      environment = {
        TZ = "Asia/Seoul"
      }
    }
    # Keycloak
    "keycloak" = {
      dockerfile_path   = null # uses official image
      container_image   = "quay.io/keycloak/keycloak:26.0"
      container_port    = 8080
      cpu               = 512
      memory            = 1024
      desired_count     = 1
      enable_alb        = false
      health_check_path = "/health/ready"
      task_role         = "default"
      environment = {
        TZ                = "Asia/Seoul"
        KC_HTTP_ENABLED   = "true"
        KC_HEALTH_ENABLED = "true"
        KC_DB             = "postgres"
      }
    }
  }

  # Service names list for ECR repos (exclude keycloak which uses official image)
  ecr_services = [for name, svc in local.services : name if svc.dockerfile_path != null]

  # Services grouped by task role
  auth_services    = [for name, svc in local.services : name if try(svc.task_role, "default") == "auth"]
  booking_services = [for name, svc in local.services : name if try(svc.task_role, "default") == "booking"]
  ai_services      = [for name, svc in local.services : name if try(svc.task_role, "default") == "travel-ai"]

  common_tags = merge(var.default_tags, {
    Environment = var.environment
  })
}
