# 인프라 구축 개요
## 기술 스택
| 분야 | 사용 기술 스택 |
| :---: | :----: |
| 컨테이너 | Docker |
| 오케스트레이션 | Kubernetes |
| CI | Jenkins |
| CD | ArgoCD |
| Broker | Kafka |
| IaC | Terraform |

### 로컬 개발 환경
#### kind 
- 로컬 k8s 클러스터 구축에 사용

### 프로덕션 환경
#### EKS
- 배포 환경에서의 클러스터 구축에 사용

### ~~통합 테스트 환경~~