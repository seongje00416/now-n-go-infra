FROM eclipse-temurin:21-jre-jammy

ARG KAFKA_VERSION=3.9.1
ARG SCALA_VERSION=2.13

ENV KAFKA_HOME=/opt/kafka
ENV PATH="${KAFKA_HOME}/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        dumb-init \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r kafka --gid=1000 \
    && useradd -r -g kafka --uid=1000 kafka \
    && curl -fsSL \
        "https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz" \
        -o /tmp/kafka.tgz \
    && tar -xzf /tmp/kafka.tgz -C /opt \
    && mv /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} ${KAFKA_HOME} \
    && rm /tmp/kafka.tgz \
    && mkdir -p /var/kafka/logs \
    && chown -R kafka:kafka ${KAFKA_HOME} /var/kafka

COPY --chown=kafka:kafka docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

VOLUME ["/var/kafka/logs"]

USER kafka
WORKDIR ${KAFKA_HOME}

EXPOSE 9092 9093

ENTRYPOINT ["dumb-init", "--", "/usr/local/bin/docker-entrypoint.sh"]