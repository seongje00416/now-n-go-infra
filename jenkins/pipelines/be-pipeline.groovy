// BE 서비스 CI 파이프라인
// develop 브랜치 polling → Docker multi-stage 빌드 → Registry Push → 매니페스트 업데이트
pipeline {
    agent any

    environment {
        REGISTRY       = 'localhost:5000'
        BE_REPO_URL    = "${GITHUB_BE_REPO_URL}"
        INFRA_REPO_URL = "${GITHUB_INFRA_REPO_URL}"
        IMAGE_TAG      = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout BE') {
            steps {
                dir('be') {
                    git branch: 'develop',
                        url: "${BE_REPO_URL}",
                        credentialsId: 'github-pat'
                }
            }
        }

        stage('Docker Build & Push') {
            parallel {
                stage('gateway-service') {
                    steps {
                        dir('be') {
                            sh """
                                docker build \
                                    -t ${REGISTRY}/gateway-service:${IMAGE_TAG} \
                                    -f domain/auth/gateway-service/Dockerfile .
                                docker push ${REGISTRY}/gateway-service:${IMAGE_TAG}
                            """
                        }
                    }
                }
                stage('user-command-service') {
                    steps {
                        dir('be') {
                            sh """
                                docker build \
                                    -t ${REGISTRY}/user-command-service:${IMAGE_TAG} \
                                    -f domain/auth/user-command-service/Dockerfile .
                                docker push ${REGISTRY}/user-command-service:${IMAGE_TAG}
                            """
                        }
                    }
                }
                stage('user-query-service') {
                    steps {
                        dir('be') {
                            sh """
                                docker build \
                                    -t ${REGISTRY}/user-query-service:${IMAGE_TAG} \
                                    -f domain/auth/user-query-service/Dockerfile .
                                docker push ${REGISTRY}/user-query-service:${IMAGE_TAG}
                            """
                        }
                    }
                }
                stage('email-service') {
                    steps {
                        dir('be') {
                            sh """
                                docker build \
                                    -t ${REGISTRY}/email-service:${IMAGE_TAG} \
                                    -f domain/auth/email-service/Dockerfile .
                                docker push ${REGISTRY}/email-service:${IMAGE_TAG}
                            """
                        }
                    }
                }
                stage('keycloak') {
                    steps {
                        dir('be') {
                            sh """
                                cat > Dockerfile.keycloak <<'DEOF'
FROM quay.io/keycloak/keycloak:26.0
COPY common/auth/keycloak/theme/ /opt/keycloak/themes/
COPY common/auth/keycloak/docker/keycloak/realm-export.json /tmp/realm-export-template.json
COPY common/auth/keycloak/docker/keycloak/init-realm.sh /tmp/init-realm.sh
USER root
RUN chmod +x /tmp/init-realm.sh
USER keycloak
ENTRYPOINT ["/bin/bash", "/tmp/init-realm.sh"]
DEOF
                                docker build \
                                    -t ${REGISTRY}/keycloak-local:${IMAGE_TAG} \
                                    -f Dockerfile.keycloak .
                                docker push ${REGISTRY}/keycloak-local:${IMAGE_TAG}
                            """
                        }
                    }
                }
            }
        }

        stage('Update Manifests') {
            steps {
                dir('infra') {
                    git branch: 'develop',
                        url: "${INFRA_REPO_URL}",
                        credentialsId: 'github-pat'

                    sh """
                        cd environments/local/manifests/ci

                        sed -i 's|image: ${REGISTRY}/gateway-service:.*|image: ${REGISTRY}/gateway-service:${IMAGE_TAG}|' gateway-service.yaml
                        sed -i 's|image: ${REGISTRY}/user-command-service:.*|image: ${REGISTRY}/user-command-service:${IMAGE_TAG}|' user-command-service.yaml
                        sed -i 's|image: ${REGISTRY}/user-query-service:.*|image: ${REGISTRY}/user-query-service:${IMAGE_TAG}|' user-query-service.yaml
                        sed -i 's|image: ${REGISTRY}/email-service:.*|image: ${REGISTRY}/email-service:${IMAGE_TAG}|' email-service.yaml
                        sed -i 's|image: ${REGISTRY}/keycloak-local:.*|image: ${REGISTRY}/keycloak-local:${IMAGE_TAG}|' keycloak.yaml
                    """

                    sh """
                        git config user.name 'Jenkins CI'
                        git config user.email 'jenkins@local'
                        git add environments/local/manifests/ci/
                        git commit -m "ci: BE 이미지 태그 업데이트 → ${IMAGE_TAG}" || echo 'No changes to commit'
                        git push origin develop
                    """
                }
            }
        }
    }

    post {
        success {
            echo "BE 파이프라인 성공 — 이미지 태그: ${IMAGE_TAG}"
        }
        failure {
            echo 'BE 파이프라인 실패'
        }
        always {
            cleanWs()
        }
    }
}
