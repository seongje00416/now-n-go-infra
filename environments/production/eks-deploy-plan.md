현재 루트 경로의 environments/production 경로 하위에 있는 Terraform 파일들을 통해 서비스 배포를 위한 인프라를 구축할 거야. 구현하고자 하는 것은 다음과 같아.

1. AWS EKS
- MSA로 마이크로 서비스를 배포하고 운영하고자 하는 컨테이너 오케스트레이션 환경
- t3.xlarge 수준의 워커 노드 2개
- 서비스 배포를 위한 prod 네임스페이스 필요

2. ECR
- 우리가 만든 서비스들을 빌드한 커스텀 이미지들을 보관하기 위한 레지스트리
- 만약 AWS에 해당 이름으로 한 레포지토리가 존재한다면 생성하는 과정을 건너뛴다.
- terraform destroy할 때 삭제가 되지 않도록 하며 terraform destroy할 때 ECR을 삭제하는 과정은 건너뛴다.

3. S3
- 서비스에서 공용으로 사용하고자 하는 S3.
- 현재 S3.tf 파일에 작성되어 있는대로 사용

4. RDS
- PostgreSQL로 운영하는 관계형 데이터베이스

5. ArgoCD
- 이 경로 하나 상위 경로에 있는 mzc-final-project-argo라는 레포지토리를 바라보며 변화를 감지하고 정의된 서비스를 EKS에 배포하는 역할
- 현재 argocd.tf에 정의된 설정 그대로 사용

가능하면 현재 만들어진 서비스의 설정은 바꾸지 않았으면 해. 인프라는 잘 올라가는데 생기는 문제는 서비스들이 배포되어서 실행이 잘 되지 않는다는 점이야.
우리가 이렇게 만든 인프라에 배포하고자 하는 서비스는 루트 경로 하나 상위 경로에 있는 mzc-final-project-be 레포지토리에 있는 서비스들이야. 그 경로에 있는 docker-compose.infra.yml, docker-compose.data.yml, docker-compose.app.yml로 로컬에서 실행하던 서비스를 EKS에 그대로 올린다고 생각하면 돼. 다만 다른 점은 docker-compose로 실행할 때는 각 서비스 모듈에서 application.yml 프로필을 application-docker.yml을 사용했는데 EKS 환경에서는 k8s라는 프로필을 사용하고 싶어.

배포를 위해 먼저 아래 작업을 진행하고 싶어.
1. mzc-final-project-be 레포지토리에서 만들어진 서비스들이 EKS 환경에서는 application-k8s.yml이라는 프로필을 사용하게 만들고 싶어.
2. EKS 파드에서 실행될 수 있는 환경을 application-k8s.yml을 통해 정의하고 싶어.
3. ~-read-servie, ~-write-service의 경우 DB에 접근하는데 기존에 사용하던 로컬 PostgreSQL DB가 아닌 위에서 만든 RDS PostgreSQL DB를 사용하게 만들고 싶어.
4. docker-compose.infra.yml에 정의된 서비스에 대해선 mzc-final-project-argo에 infra/경로에 보면 아마 각 서비스별로 정의되어 있을 거야. 그걸 최대한 활용해서 EKS에서 작동되게 만들고 싶어.
5. 최대한 terraform apply 한 번에 위 작업들이 모두 이루어졌으면 좋겠어.
6. 혹시나 로컬에서 실행해야 하는 명령어가 있다면 Windows Powershell에서 실행한다는 기준으로 작성해줘. `나 \로 줄바꿈이 안되고 grep 같은 명령어도 안돼. 이거 중요해. 
7. docker-compose 파일에 정의되어 있던 서비스들을 돌아보면서 k8s에서 실행할 때 문제가 될 것 같은 부분들을 정리해서 알려줘. 그 부분에 대해서 어떻게 수정해야 할지 방향성을 잡아줄게.