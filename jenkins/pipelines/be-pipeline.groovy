// BE 서비스 CI 파이프라인
// feature 브랜치 polling → Docker multi-stage 빌드 → Registry Push → 매니페스트 업데이트
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
                    git branch: 'feature/hsj/22-ivs-live-commerce',
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
                stage('user-write-service') {
                    steps {
                        dir('be') {
                            sh """
                                docker build \
                                    -t ${REGISTRY}/user-write-service:${IMAGE_TAG} \
                                    -f data/auth/user-write-service/Dockerfile .
                                docker push ${REGISTRY}/user-write-service:${IMAGE_TAG}
                            """
                        }
                    }
                }
                stage('user-read-service') {
                    steps {
                        dir('be') {
                            sh """
                                docker build \
                                    -t ${REGISTRY}/user-read-service:${IMAGE_TAG} \
                                    -f data/auth/user-read-service/Dockerfile .
                                docker push ${REGISTRY}/user-read-service:${IMAGE_TAG}
                            """
                        }
                    }
                }
                stage('keycloak') {
                    steps {
                        dir('be/common/auth/keycloak') {
                            sh """
                                cat > Dockerfile.keycloak <<'DEOF'
FROM quay.io/keycloak/keycloak:26.0
COPY theme/ /opt/keycloak/themes/
COPY docker/keycloak/realm-export.json /tmp/realm-export-template.json
COPY docker/keycloak/init-realm.sh /tmp/init-realm.sh
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
                withCredentials([usernamePassword(credentialsId: 'github-pat', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                    dir('infra') {
                        git branch: 'local/hsj/1-individual-branch',
                            url: "${INFRA_REPO_URL}",
                            credentialsId: 'github-pat'

                        sh """
                            cd charts/ticket-service
                            sed -i 's|gatewayImageTag:.*|gatewayImageTag: "${IMAGE_TAG}"|' values.yaml
                            sed -i 's|userCommandImageTag:.*|userCommandImageTag: "${IMAGE_TAG}"|' values.yaml
                            sed -i 's|userQueryImageTag:.*|userQueryImageTag: "${IMAGE_TAG}"|' values.yaml
                            sed -i 's|userWriteImageTag:.*|userWriteImageTag: "${IMAGE_TAG}"|' values.yaml
                            sed -i 's|userReadImageTag:.*|userReadImageTag: "${IMAGE_TAG}"|' values.yaml
                            sed -i 's|emailImageTag:.*|emailImageTag: "${IMAGE_TAG}"|' values.yaml
                            sed -i 's|keycloakImageTag:.*|keycloakImageTag: "${IMAGE_TAG}"|' values.yaml
                        """

                        sh """
                            git config user.name 'Jenkins CI'
                            git config user.email 'jenkins@local'
                            git remote set-url origin https://${GIT_USER}:${GIT_PASS}@github.com/MZC-Final-Project/mzc-final-project-infra.git
                            git add charts/ticket-service/values.yaml
                            git commit -m "ci: BE 이미지 태그 업데이트 → ${IMAGE_TAG}" || echo 'No changes to commit'
                            git push origin local/hsj/1-individual-branch
                        """
                    }
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
