#!/bin/bash
set -euxo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

# 1. 시스템 업데이트
apt-get update -y
apt-get install -y git curl

# 2. Docker 설치 (Ubuntu 공식 방법)
apt-get install -y ca-certificates gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# 3. Docker Compose v2 설치
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest \
  | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
curl -SL "https://github.com/docker/compose/releases/download/v$${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
     -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 4. Infra 레포 클론
INFRA_REPO=$(echo "${github_infra_repo_url}" | sed "s|https://|https://${github_username}:${github_token}@|")
CLONE_DIR="/home/ubuntu/project-infra"

git clone "$INFRA_REPO" "$CLONE_DIR"

PROJECT_DIR="$CLONE_DIR/jenkins"

# 5. .env 파일 생성
cat > "$PROJECT_DIR/.env" <<EOF
GITHUB_USERNAME=${github_username}
GITHUB_TOKEN=${github_token}
GITHUB_BE_REPO_URL=${github_be_repo_url}
GITHUB_FE_REPO_URL=${github_fe_repo_url}
GITHUB_INFRA_REPO_URL=${github_infra_repo_url}
EOF
chmod 600 "$PROJECT_DIR/.env"

# 6. 소유권 설정 & docker-compose 실행
chown -R ubuntu:ubuntu "$CLONE_DIR"

cd "$PROJECT_DIR"
# ubuntu 유저로 docker-compose 실행 (docker 그룹 반영을 위해 su 사용)
su -s /bin/bash ubuntu -c "cd $PROJECT_DIR && docker-compose --env-file .env up -d --build"

echo "✅ Jenkins CI 서버 초기화 완료"
echo "   Jenkins UI: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000"