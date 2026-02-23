// FE 서비스 CI 파이프라인
// develop 브랜치 polling → npm build → Nginx Docker 이미지 → Registry Push → 매니페스트 업데이트
pipeline {
    agent any

    environment {
        REGISTRY       = 'localhost:5000'
        FE_REPO_URL    = "${GITHUB_FE_REPO_URL}"    // JCasC 환경변수
        INFRA_REPO_URL = "${GITHUB_INFRA_REPO_URL}" // JCasC 환경변수
        IMAGE_TAG      = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout FE') {
            steps {
                dir('fe') {
                    git branch: 'feature/hsj/19-live-commerce-test',
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
                    // Nginx 기반 정적 서빙 이미지
                    sh """
                        cat > Dockerfile.ci <<'EOF'
FROM nginx:alpine
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
                    dir('infra') {
                        git branch: 'local/hsj/1-individual-branch',
                            url: "${INFRA_REPO_URL}",
                            credentialsId: 'github-pat'

                        sh """
                            cd charts/ticket-service
                            sed -i 's|feImageTag:.*|feImageTag: "${IMAGE_TAG}"|' values.yaml
                        """

                        sh """
                            git config user.name 'Jenkins CI'
                            git config user.email 'jenkins@local'
                            git remote set-url origin https://${GIT_USER}:${GIT_PASS}@github.com/MZC-Final-Project/mzc-final-project-infra.git
                            git add charts/ticket-service/values.yaml
                            git commit -m "ci: FE 이미지 태그 업데이트 → ${IMAGE_TAG}" || echo 'No changes to commit'
                            git push origin local/hsj/1-individual-branch
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
