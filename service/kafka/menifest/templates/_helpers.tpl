{{/*
릴리스 이름 기반 공통 이름
*/}}
{{- define "kafka.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
헤드리스 서비스 이름 (StatefulSet Pod DNS에 사용)
*/}}
{{- define "kafka.headlessService" -}}
{{- printf "%s-headless" (include "kafka.name" .) }}
{{- end }}

{{/*
공통 레이블
*/}}
{{- define "kafka.labels" -}}
app.kubernetes.io/name: kafka
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
셀렉터 레이블
*/}}
{{- define "kafka.selectorLabels" -}}
app.kubernetes.io/name: kafka
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
KRaft controller.quorum.voters 동적 생성
예) replicaCount=3 → "0@kafka-0.kafka-headless:9093,1@kafka-1.kafka-headless:9093,2@kafka-2.kafka-headless:9093"
*/}}
{{- define "kafka.quorumVoters" -}}
{{- $voters := list -}}
{{- $releaseName := (include "kafka.name" .) -}}
{{- $headless := (include "kafka.headlessService" .) -}}
{{- $namespace := .Release.Namespace -}}
{{- range $i, $e := until (.Values.replicaCount | int) -}}
  {{- $voters = append $voters (printf "%d@%s-%d.%s.%s.svc.cluster.local:9093" $i $releaseName $i $headless $namespace) -}}
{{- end -}}
{{- join "," $voters }}
{{- end }}
