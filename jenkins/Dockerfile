FROM jenkins/jenkins:lts-jdk17

USER root

# Docker CLI (호스트 Docker 소켓 마운트 방식으로 사용)
RUN apt-get update && apt-get install -y \
    docker.io \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Node.js 20 (FE 빌드용)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# Jenkins 유저를 docker 그룹에 추가 (소켓 접근 권한)
RUN groupadd -f docker && usermod -aG docker jenkins

USER jenkins

# 플러그인 사전 설치
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# JCasC 설정
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc
COPY casc/ /usr/share/jenkins/ref/casc/
