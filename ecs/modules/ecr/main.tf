# =============================================================================
# ECR (Elastic Container Registry) 모듈
# 서비스별 컨테이너 이미지 저장소를 생성한다.
# for_each를 사용해 service_names 목록으로부터 저장소를 동적으로 생성한다.
# =============================================================================

# -----------------------------------------------------------------------------
# ECR 저장소 — 서비스 이름마다 하나씩 생성
# -----------------------------------------------------------------------------
resource "aws_ecr_repository" "this" {
  for_each = toset(var.service_names)

  name                 = "${var.project_name}/${each.key}"
  image_tag_mutability = "MUTABLE" # CI/CD에서 latest 태그 덮어쓰기 허용

  # 푸시 시 이미지 자동 취약점 스캔
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "${var.project_name}/${each.key}"
    Project = var.project_name
    Module  = "ecr"
  }
}

# -----------------------------------------------------------------------------
# ECR 수명 주기 정책 — 최근 10개 이미지만 유지하여 스토리지 비용 절감
# -----------------------------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = toset(var.service_names)
  repository = aws_ecr_repository.this[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "최근 10개 이미지만 유지"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
