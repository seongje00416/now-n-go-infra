# ============================================================
# ECR (Elastic Container Registry) - 서비스별 이미지 저장소
#  레포지토리명: <cluster_name>/<service-name>
#  이미 존재하는 레포지토리는 건너뜀 (idempotent)
# ============================================================

resource "null_resource" "ecr_repos" {
  for_each = toset(var.ecr_repositories)

  triggers = {
    repo_name = "${var.cluster_name}/${each.key}"
  }

  provisioner "local-exec" {
    # describe 성공(이미 존재) → 건너뜀 / 실패(없음) → create
    command = "aws ecr describe-repositories --repository-names ${var.cluster_name}/${each.key} --region ${var.aws_region} 2>nul || aws ecr create-repository --repository-name ${var.cluster_name}/${each.key} --region ${var.aws_region} --image-tag-mutability MUTABLE --image-scanning-configuration scanOnPush=true"
  }
}
