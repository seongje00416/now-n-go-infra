// FE 서비스 CI 파이프라인
// feature 브랜치 polling → npm build → Nginx Docker 이미지 → Registry Push → 매니페스트 업데이트
pipeline {
    agent any

    environment {
        REGISTRY       = 'localhost:5000'
        FE_REPO_URL    = "${GITHUB_FE_REPO_URL}"    // JCasC 환경변수
        ARGO_REPO_URL  = "${GITHUB_ARGO_REPO_URL}"  // JCasC 환경변수
        IMAGE_TAG      = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout FE') {
            steps {
                dir('fe') {
                    git branch: 'develop',
                        url: "${FE_REPO_URL}",
                        credentialsId: 'github-pat'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                dir('fe') {
                    sh 'npm ci'
                }
            }
        }

        stage('Build') {
            steps {
                dir('fe') {
                    sh 'npm run build'
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                dir('fe') {
                    // Nginx 기반 정적 서빙 + API 리버스 프록시 이미지
                    sh """
                        cat > nginx.conf <<'NGINX'
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    # API 요청 → gateway-service 프록시
    location /api/ {
        proxy_pass http://gateway-service:8080;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$http_host;
    }

    # OAuth2 로그인/콜백 → gateway-service
    location /oauth2/ {
        proxy_pass http://gateway-service:8080;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$http_host;
    }

    location /login/oauth2/ {
        proxy_pass http://gateway-service:8080;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$http_host;
    }

    # 로그아웃 → gateway-service
    location /logout {
        proxy_pass http://gateway-service:8080;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$http_host;
    }

    # Actuator → gateway-service
    location /actuator/ {
        proxy_pass http://gateway-service:8080;
        proxy_set_header Host \$http_host;
    }

    # SPA 라우팅 — 정적 파일 없으면 index.html
    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
NGINX
                        cat > Dockerfile.ci <<'EOF'
FROM nginx:alpine
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY dist/ /usr/share/nginx/html/
EXPOSE 80
EOF
                        docker build \
                            -t ${REGISTRY}/frontend:${IMAGE_TAG} \
                            -f Dockerfile.ci .
                        docker push ${REGISTRY}/frontend:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Update Manifests') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-pat', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                    dir('argo') {
                        git branch: 'develop',
                            url: "${ARGO_REPO_URL}",
                            credentialsId: 'github-pat'

                        sh """
                            cd charts/ticket-service
                            sed -i 's|feImageTag:.*|feImageTag: "${IMAGE_TAG}"|' values.yaml
                        """

                        sh """
                            git config user.name 'Jenkins CI'
                            git config user.email 'jenkins@local'
                            git remote set-url origin https://${GIT_USER}:${GIT_PASS}@github.com/MZC-Final-Project/mzc-final-project-argo.git
                            git add charts/ticket-service/values.yaml
                            git commit -m "ci: FE 이미지 태그 업데이트 → ${IMAGE_TAG}" || echo 'No changes to commit'
                            git push origin develop
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "FE 파이프라인 성공 — 이미지 태그: ${IMAGE_TAG}"
        }
        failure {
            echo 'FE 파이프라인 실패'
        }
        always {
            cleanWs()
        }
    }
}
