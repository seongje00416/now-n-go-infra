# main.tf : 실제 인프라를 위한 정의

# terraform : 이 파일에서 정의할 내용이 Terraform이라는 것을 의미
terraform {
  required_version = ">= 1.0"                           # Terraform 실행 파일의 최소 버전 설정
  
  # required_providers : 이 파일에서 사용하고자 하는 프로바이더들을 정의
  #  Provider: 특정 인프라(AWS, GCP, K8S, Kind 등)를 이 파일에서 사용하기 위한 플러그인
  required_providers {
    # privider 이름 = { source = "다운로드 할 경로", version = "버전" }   형태로 지정
    #  ~> n.x : n버전만 다룸 ( ex. ~> 3.5 : 3.5.1, 3.5.2, ... 3.5.x 까지만 사용, 3.6은 허용하지 않음 )
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.4"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# resource "리소스 타입" "이름" : 파일에서 관리하고자 하는 인프라 리소스 정의 
#  리소스 타입은 위에서 정의한 프로바이더에 따라 정해진 이름이 있음 ( kind는 kind_cluster라는 이름이 있음 )

# Kind 클러스터 생성 ( Kind: Kubernetes IN Docker라는 의미로 로컬에서 Docker를 통해 클러스터를 구축할 수 있는 환경을 만들어주는 도구 )
#  다른 곳에서 해당 리소스를 호출할 때는 kind_cluster.default 형태로 호출
resource "kind_cluster" "default" {
  name            = var.cluster_name                # k8s 클러스터 이름 설정. 변수를 사용해 설정
  wait_for_ready  = true                            # 클러스터가 준비될 때까지 다른 작업 없이 대기
  
  # 클러스터에 대한 상세 설정을 위한 블록
  kind_config {
    kind        = "Cluster"                         # kind를 통해 정의할 리소스 타입
    api_version = "kind.x-k8s.io/v1alpha4"          # Kind API 버전 지정
    
    # k8s 노드 설정
    node {
      role = "control-plane"                        # 해당 노드의 역할 "control-plane" vs. "worker"

      # 호스트 ↔ 컨테이너 포트 매핑 (port-forward 없이 localhost로 접근 가능)
      extra_port_mappings {
        container_port = 30070                      # NodePort로 노출할 ArgoCD 포트
        host_port      = 8080                       # 호스트에서 접근할 포트
        protocol       = "TCP"
      }
      extra_port_mappings {
        container_port = 30080                      # NodePort로 노출할 Gateway 포트
        host_port      = 8443                       # 호스트에서 접근할 포트 (FE 프록시 대상)
        protocol       = "TCP"
      }
      extra_port_mappings {
        container_port = 30090                      # NodePort로 노출할 Keycloak 포트
        host_port      = 9090                       # 호스트에서 접근할 포트
        protocol       = "TCP"
      }
      extra_port_mappings {
        container_port = 30100                      # NodePort로 노출할 MinIO S3 API 포트
        host_port      = 9000                       # 호스트에서 접근할 포트
        protocol       = "TCP"
      }
      extra_port_mappings {
        container_port = 30101                      # NodePort로 노출할 MinIO Console 포트
        host_port      = 9001                       # 호스트에서 접근할 포트
        protocol       = "TCP"
      }
      extra_port_mappings {
        container_port = 30030                      # NodePort로 노출할 Frontend 포트
        host_port      = 3000                       # 호스트에서 접근할 포트
        protocol       = "TCP"
      }
      extra_port_mappings {
        container_port = 30025                      # NodePort로 노출할 MailHog 웹 UI 포트
        host_port      = 8025                       # 호스트에서 접근할 포트
        protocol       = "TCP"
      }
    }
    
    # Worker 노드 추가 (var.worker_node_count 만큼 생성)
    #  RAM 16GB 이하: worker_node_count = 1 권장
    #  RAM 32GB 이상: worker_node_count = 2 권장
    dynamic "node" {
      for_each = range(var.worker_node_count)
      content {
        role = "worker"
      }
    }

    # 로컬 Docker Registry 미러링 (localhost:5000 → local-registry 컨테이너)
    containerd_config_patches = [
      <<-TOML
        [plugins."io.containerd.grpc.v1.cri".registry]
          config_path = "/etc/containerd/certs.d"
      TOML
    ]
  }
}

# Kind 노드에 로컬 레지스트리 설정 배포 (클러스터 생성 후 실행)
resource "null_resource" "registry_config" {
  depends_on = [kind_cluster.default]

  provisioner "local-exec" {
    command = <<-EOT
      for node in $(kind get nodes --name ${var.cluster_name}); do
        docker exec "$node" bash -c "
          mkdir -p /etc/containerd/certs.d/localhost:5000
          cat > /etc/containerd/certs.d/localhost:5000/hosts.toml <<'EOF'
[host.\"http://local-registry:5000\"]
  capabilities = [\"pull\", \"resolve\", \"push\"]
EOF
        "
      done
    EOT
  }
}

# Jenkins + Registry 컨테이너를 Kind 네트워크에 연결
resource "null_resource" "jenkins_compose" {
  depends_on = [kind_cluster.default]

  provisioner "local-exec" {
    command     = "docker compose up -d"
    working_dir = "${path.module}/../../jenkins"
  }
}

# Kubernetes Provider 설정
#  실제 k8s를 설정하는 부분
provider "kubernetes" {
  host                   = kind_cluster.default.endpoint                        # kind_cluster의 default 클러스터의 엔드포인트로 설정
  cluster_ca_certificate = kind_cluster.default.cluster_ca_certificate          # 클러스터 인증서 등록 -> 신뢰할 수 있는 클러스터인지
  client_certificate     = kind_cluster.default.client_certificate              # 이 코드를 실행하는 사용자 인증서 -> 이 코드가 신뢰된 사용자로부터 정의되고 실행되고 있는지
  client_key             = kind_cluster.default.client_key                      # 위 인증서에 대응하는 키
}

# Kubectl Provider 설정
#  kubectl_manifest 리소스 사용을 위한 설정(쿠버네티스 YAML manifest를 직접 적용할 수 있게 해주는 서드파티 provider)
provider "kubectl" {
  host                   = kind_cluster.default.endpoint
  cluster_ca_certificate = kind_cluster.default.cluster_ca_certificate
  client_certificate     = kind_cluster.default.client_certificate
  client_key             = kind_cluster.default.client_key
  load_config_file       = false
}

# Helm Provider 설정
#  Helm을를 사용하기 위한 설정
provider "helm" {
  # 해당 helm 리소스와 연결하기 위한 쿠버네티스 정보 등록
  kubernetes {
    host                   = kind_cluster.default.endpoint     
    client_certificate     = kind_cluster.default.client_certificate
    client_key             = kind_cluster.default.client_key
    insecure               = true   # 로컬 개발을 위해 TLS 검증 우회
  }
}

# Namespace 생성
#  클러스터 내 네임스페이스들을 설정
#  네임스페이스는 클러스터 내 독립적인 분리 공간이기 때문에 역할 별로 분리 가능
resource "kubernetes_namespace" "namespaces" {
  for_each = toset(var.namespaces)           # 변수에 리스트로 선언했던 네임스페이스들을 반복문을 통해 한 번에 여러 개 생성
  
  # 각 네임스페이스의 메타데이터 설정
  metadata {
    name = each.value                   # 네임스페이스 이름 설정, each.value는 현재 반복중인 값을 의미
    labels = {                          # 해당 네임스페이스에 붙일 라벨 -> Key-Value 쌍으로 설정
      environment = "local"
      managed-by  = "terraform"
    }
  }
}

# MetalLB 설정
#  로컬에서 로드밸런서 타입 서비스를 지원하기 위해 필요
resource "helm_release" "metallb" {
  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  namespace  = "metallb-system"
  version    = "0.13.12"

  create_namespace = true

  # Speaker (DaemonSet) 리소스 제한 - OOMKilled 방지
  set {
    name  = "speaker.resources.limits.memory"
    value = "256Mi"
  }
  set {
    name  = "speaker.resources.requests.memory"
    value = "128Mi"
  }
  set {
    name  = "speaker.resources.limits.cpu"
    value = "200m"
  }
  set {
    name  = "speaker.resources.requests.cpu"
    value = "100m"
  }

  # FRR 컨테이너 리소스 제한
  set {
    name  = "speaker.frr.resources.limits.memory"
    value = "128Mi"
  }
  set {
    name  = "speaker.frr.resources.requests.memory"
    value = "64Mi"
  }

  # Controller 리소스 제한
  set {
    name  = "controller.resources.limits.memory"
    value = "128Mi"
  }
  set {
    name  = "controller.resources.requests.memory"
    value = "64Mi"
  }

  depends_on = [kind_cluster.default]
}

# MetalLB IP Pool 설정
#  MetalLB는 k8s와 다른 독립적인 기술 스택이기 때문에 helm이나 kubernetse provider로 정의할 수 없음
#  -> kubectl을 사용해 직접 YAML 파일에 접근해 수정
resource "kubectl_manifest" "metallb_ippool" {
  # 만들어지는 YAML 파일에 정의할 내용
  # -> k8s의 menifest 파일을 작성하는 것이기 때문에 해당 내용 그대로 작성

  # apiVersion: metallb의 IP Pool 설정을 위한 API 버전
  # kind: 리소스 타입
  # metadata: 메타데이터 설정
  # name: 해당 IP Pool의 이름
  # namespace: 해당 리소스를 만들 네임스페이스
  # spec: 리소스의 상세 설정
  # addresses: 이 파일을 통해 만들어지는 IP Pool을 사용할 로드밸런서가 할당할 수 있는 IP 범위 설정
  yaml_body = <<-YAML
    apiVersion: metallb.io/v1beta1
    kind: IPAddressPool
    metadata:
      name: local-pool
      namespace: metallb-system
    spec:
      addresses:
      - 172.18.255.200-172.18.255.250
  YAML
  
  # 앞서 만든 metallb가 먼저 만들어져야 설정을 적용할 수 있기 때문에 의존성 등록
  depends_on = [helm_release.metallb]
}

resource "kubectl_manifest" "metallb_l2advertisement" {
  yaml_body = <<-YAML
    apiVersion: metallb.io/v1beta1
    kind: L2Advertisement
    metadata:
      name: local-l2
      namespace: metallb-system
    spec:
      ipAddressPools:
      - local-pool
  YAML
  
  depends_on = [helm_release.metallb]
}

# Local Storage 클래스 설정
#  로컬 환경에서 PV를 사용하기 위한 설정
resource "kubernetes_storage_class" "local_storage" {
  metadata {
    name = "local-storage"                                      # 스토리지 클래스 이름 설정
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"    # PVC 부분에서 따로 지정하지 않으면 이 스토리지 클래스를 기본값으로 사용하도록 설정
    }
  }
  
  storage_provisioner = "rancher.io/local-path"         # 실제로 스토리지를 제공하는 프로비저너 설정
  reclaim_policy      = "Delete"                        # PVC가 삭제되면 PV도 같이 삭제되도록 설정
  volume_binding_mode = "WaitForFirstConsumer"          # Pod가 스케쥴링 되면 PV를 바인딩하도록 설정( Pod에 PV를 바인딩하는 시점을 결정하는 속성)
}

# Local Path Provisioner 설치
#  로컬 경로를 PV로 사용할 수 있도록 해주는 설정
resource "helm_release" "local_path_provisioner" {
  name       = "local-path-provisioner"
  repository = "https://charts.containeroo.ch"
  chart      = "local-path-provisioner"
  namespace  = "kube-system"
  version    = "0.0.26"

  depends_on = [kind_cluster.default]
}

# app-secret (dev 네임스페이스 서비스용 크리덴셜)
resource "kubernetes_secret" "app_secret" {
  metadata {
    name      = "app-secret"
    namespace = "dev"
  }

  data = {
    # Keycloak DB
    POSTGRES_USER     = "keycloak"
    POSTGRES_PASSWORD = "keycloak1234"

    # Keycloak Admin
    KC_BOOTSTRAP_ADMIN_USERNAME = "admin"
    KC_BOOTSTRAP_ADMIN_PASSWORD = "admin"

    # BFF Client
    KEYCLOAK_CLIENT_SECRET = "bff-secret-local-dev"

    # Redis (auth)
    REDIS_PASSWORD = "redis-secret"

    # User DB
    USER_DB_USER     = "userservice"
    USER_DB_PASSWORD = "userservice1234"

    # SMTP
    SMTP_USER              = "waninokow@gmail.com"
    SMTP_PASSWORD          = "urdh iuzk rntm ucyv"
    SMTP_FROM              = "waninokow@gmail.com"
    SMTP_FROM_DISPLAY_NAME = "Ticket-Service"

    # Internal API Key
    INTERNAL_API_KEY = "k8s-internal-api-key-s3cur3"

    # Google OAuth
    GOOGLE_CLIENT_ID     = "140364443613-ff37u5fg1vbo114p5ah1pfn6erjhug99.apps.googleusercontent.com"
    GOOGLE_CLIENT_SECRET = "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"

    # Redis (business)
    REDIS_BUSINESS_PASSWORD = "redis-biz-secret"

    # Booking DB
    BOOKING_DB_USER     = "bookingservice"
    BOOKING_DB_PASSWORD = "bookingservice1234"

    # Encryption Keys (AES-256 + HMAC)
    ENCRYPTION_AES_KEY  = "gdP8yw1/oi3NNCfC5H/2/URZrhzSONpt8K/cCB1F9gk="
    ENCRYPTION_HMAC_KEY = "6ZtrrKC4Tg5NLKFPf1g8oivr64bNSJIXHpeJfE/Xcws="

    # S3 (MinIO)
    S3_ACCESS_KEY = "minioadmin"
    S3_SECRET_KEY = "minioadmin1234"
  }

  depends_on = [kubernetes_namespace.namespaces]
}