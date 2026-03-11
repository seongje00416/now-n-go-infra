# ============================================================
# Bedrock Guardrail — travel-ai RAG 시스템 가드레일
# ============================================================
# 콘텐츠 필터, 주제 제한, PII 감지, 단어 필터, 컨텍스트 기반 검증
# ============================================================

resource "aws_bedrock_guardrail" "travel_ai" {
  name                     = "travel-ai-guardrail-${var.environment}"
  description              = "Now & Go 여행 AI 플래너용 가드레일 — 콘텐츠/PII/주제 필터링"
  blocked_input_messaging  = "여행과 관련 없는 요청은 처리할 수 없습니다. 여행 관련 질문을 입력해주세요."
  blocked_outputs_messaging = "적절한 응답을 생성할 수 없습니다. 다시 시도해주세요."

  # ----------------------------------------------------------
  # 콘텐츠 필터 — 유해 콘텐츠 차단 (입력 + 출력)
  # ----------------------------------------------------------
  content_policy_config {
    filters_config {
      type            = "HATE"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
    filters_config {
      type            = "INSULTS"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
    filters_config {
      type            = "SEXUAL"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
    filters_config {
      type            = "VIOLENCE"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
    filters_config {
      type            = "MISCONDUCT"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
    filters_config {
      type            = "PROMPT_ATTACK"
      input_strength  = "HIGH"
      output_strength = "NONE"
    }
  }

  # ----------------------------------------------------------
  # 주제 제한 — 여행과 무관한 주제 거부
  # ----------------------------------------------------------
  topic_policy_config {
    topics_config {
      name       = "Politics"
      definition = "Political opinions, elections, political parties, and politicians"
      type       = "DENY"
      examples   = [
        "어느 정당을 지지해야 하나요?",
        "대통령 선거에 대해 알려줘",
      ]
    }
    topics_config {
      name       = "Religious Debate"
      definition = "Religious superiority comparisons, interfaith conflicts, and proselytizing"
      type       = "DENY"
      examples   = [
        "어떤 종교가 가장 좋은가요?",
        "무신론이 옳은 이유를 설명해줘",
      ]
    }
    topics_config {
      name       = "Illegal Activity"
      definition = "Drugs, smuggling, illegal gambling, and criminal activities"
      type       = "DENY"
      examples   = [
        "해외에서 마약 구하는 방법",
        "카지노에서 사기치는 방법",
      ]
    }
    topics_config {
      name       = "Code Generation"
      definition = "Programming code generation, hacking, and system manipulation"
      type       = "DENY"
      examples   = [
        "파이썬 코드 작성해줘",
        "SQL 인젝션 방법을 알려줘",
      ]
    }
    topics_config {
      name       = "Medical Advice"
      definition = "Medical diagnosis, prescriptions, and treatment advice (excluding travel health tips)"
      type       = "DENY"
      examples   = [
        "이 약을 먹어도 되나요?",
        "두통이 있는데 무슨 병인가요?",
      ]
    }
  }

  # ----------------------------------------------------------
  # 단어 필터 — 비속어/욕설 차단
  # ----------------------------------------------------------
  word_policy_config {
    managed_word_lists_config {
      type = "PROFANITY"
    }
    words_config {
      text = "시발"
    }
    words_config {
      text = "개새끼"
    }
    words_config {
      text = "병신"
    }
    words_config {
      text = "씹"
    }
    words_config {
      text = "좆"
    }
  }

  # ----------------------------------------------------------
  # PII 감지 — 개인정보 익명화
  # ----------------------------------------------------------
  sensitive_information_policy_config {
    pii_entities_config {
      type   = "EMAIL"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "PHONE"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "CREDIT_DEBIT_CARD_NUMBER"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "AWS_ACCESS_KEY"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "AWS_SECRET_KEY"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "IP_ADDRESS"
      action = "ANONYMIZE"
    }
  }

  # ----------------------------------------------------------
  # 컨텍스트 기반 검증 — 검색 결과에 기반한 답변 강제
  # ----------------------------------------------------------
  contextual_grounding_policy_config {
    filters_config {
      type      = "GROUNDING"
      threshold = 0.7
    }
    filters_config {
      type      = "RELEVANCE"
      threshold = 0.7
    }
  }

  tags = {
    Environment = var.environment
    Module      = "travel-ai"
  }
}

# ============================================================
# Guardrail 버전 — 프로덕션 고정 버전
# ============================================================
resource "aws_bedrock_guardrail_version" "travel_ai" {
  guardrail_arn = aws_bedrock_guardrail.travel_ai.guardrail_arn
  description   = "Initial version"
}
