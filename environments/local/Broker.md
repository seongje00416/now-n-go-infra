## Kafka
### Spring Boot 서버 설정
```
spring:
  kafka:
    bootstrap-servers: kafka.kafka.svc.cluster.local:9092
```

## Redis
### 비밀번호 설정
- terraform.tfvars 폴더에 redis_password에 설정
### Spring Boot host 설정
```
spring:
  data:
    redis:
      host: redis-master.redis.svc.cluster.local
      port: 6379
      password: 앞서 작성한 비밀번호
```