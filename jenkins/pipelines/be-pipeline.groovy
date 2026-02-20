// BE 서비스 CI 파이프라인
// develop 브랜치 polling → Gradle 빌드 → Docker 이미지 빌드 → Registry Push → 매니페스트 업데이트
pipeline {
    agent any

    environment {
        REGISTRY      = 'localhost:5000'
        BE_REPO       = credentials('github-pat')  // JCasC에서 설정한 credential ID
        BE_REPO_URL   = "${GITHUB_BE_REPO_URL}"    // JCasC 환경변수
        INFRA_REPO_URL = "${GITHUB_INFRA_REPO_URL}" // JCasC 환경변수
        IMAGE_TAG     = "${BUILD_NUMBER}"
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

        stage('Gradle Build') {
            steps {
                dir('be/common/auth/keycloak') {
                    sh 'chmod +x gradlew'
                    sh './gradlew clean build -x test --no-daemon'
                }
            }
        }

        stage('Docker Build & Push') {
            parallel {
                stage('gateway-service') {
                    steps {
                        dir('be/common/auth/keycloak') {
                            sh """
                                docker build \
                                    -t ${REGISTRY}/gateway-service:${IMAGE_TAG} \
                                    -f gateway-service/Dockerfile .
                                docker push ${REGISTRY}/gateway-service:${IMAGE_TAG}
                            """
                        }
                    }
                }
                stage('user-command-service') {
                    steps {
                        dir('be') {
                            // user-command-service는 별도 Dockerfile이 없으므로 인라인 생성
                            sh """
                                cat > domain/auth/user-command-service/Dockerfile.ci <<'EOF'
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
COPY domain/auth/user-command-service/build/libs/*-SNAPSHOT.jar app.jar
EXPOSE 8086
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF
                                docker build \
                                    -t ${REGISTRY}/user-command-service:${IMAGE_TAG} \
                                    -f domain/auth/user-command-service/Dockerfile.ci .
                                docker push ${REGISTRY}/user-command-service:${IMAGE_TAG}
                            """
                        }
                    }
                }
                stage('user-query-service') {
                    steps {
                        dir('be') {
                            sh """
                                cat > domain/auth/user-query-service/Dockerfile.ci <<'EOF'
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
COPY domain/auth/user-query-service/build/libs/*-SNAPSHOT.jar app.jar
EXPOSE 8087
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF
                                docker build \
                                    -t ${REGISTRY}/user-query-service:${IMAGE_TAG} \
                                    -f domain/auth/user-query-service/Dockerfile.ci .
                                docker push ${REGISTRY}/user-query-service:${IMAGE_TAG}
                            """
                        }
                    }
                }
                stage('email-service') {
                    steps {
                        dir('be') {
                            sh """
                                cat > common/auth/keycloak/email-service/Dockerfile.ci <<'EOF'
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
COPY common/auth/keycloak/email-service/build/libs/*-SNAPSHOT.jar app.jar
EXPOSE 8085
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF
                                docker build \
                                    -t ${REGISTRY}/email-service:${IMAGE_TAG} \
                                    -f common/auth/keycloak/email-service/Dockerfile.ci .
                                docker push ${REGISTRY}/email-service:${IMAGE_TAG}
                            """
                        }
                    }
                }
                stage('keycloak') {
                    steps {
                        dir('be/common/auth/keycloak') {
                            // deploy-local.sh의 Keycloak 인라인 Dockerfile 재현
                            sh """
                                cat > Dockerfile.keycloak <<'EOF'
FROM quay.io/keycloak/keycloak:26.0
COPY theme/ /opt/keycloak/themes/
COPY docker/keycloak/realm-export.json /tmp/realm-export-template.json
COPY docker/keycloak/init-realm.sh /tmp/init-realm.sh
USER root
RUN chmod +x /tmp/init-realm.sh
USER keycloak
ENTRYPOINT ["/bin/bash", "/tmp/init-realm.sh"]
EOF
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

                        # 앱 서비스 이미지 태그 업데이트
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
