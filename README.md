# LLM Security Lab

Docker 기반 LLM 보안 진단 실습 환경. 가상의 금융회사 "한빛금융" AI 서비스 3종을 대상으로 취약점 진단을 수행

| 서비스 | URL | 난이도 | 핵심 취약점 |
|--------|-----|--------|-------------|
| 고객상담 AI | http://localhost:5051 | ★☆☆ | System Prompt Leakage, Prompt Injection |
| 사내 도우미 | http://localhost:5052 | ★★☆ | RAG Data Leakage, Indirect Prompt Injection |
| 업무자동화 API | http://localhost:5053 | ★★★ | Excessive Agency, SSRF, Insecure Auth |

## 사전 준비

**Docker Desktop**, **Ollama**, **Node.js**(Promptfoo용) 설치 필요

```
wsl --install
winget install Docker.DockerDesktop
winget install Ollama.Ollama
winget install OpenJS.NodeJS.LTS
```

WSL 설치 후 재부팅 필요. Docker Desktop은 설치 후 실행하여 트레이에서 "Running" 상태 확인

Ollama 모델 다운로드:

```
ollama pull qwen2.5:3b
ollama pull qwen2.5:7b
```

- `qwen2.5:3b` — 챗봇 응답용 (~2GB)
- `qwen2.5:7b` — Promptfoo judge용 (~4.5GB)

## 설치 및 실행

```
.\install.bat         # 최초 설치
.\start.bat           # 시작
.\stop.bat            # 종료
.\check.bat           # 상태 확인
.\reset.bat           # 초기화
.\uninstall.bat       # 삭제
```

## 실습

### 1. 수동 테스트

브라우저에서 각 챗봇 접속 후 공격 시도

### 2. API 호출

```
curl -X POST http://localhost:5051/api/chat -H "Content-Type: application/json" -d "{\"message\": \"테스트\"}"
```

업무자동화 API는 토큰 발급 후 사용:

```
curl -X POST http://localhost:5053/api/auth -H "Content-Type: application/json" -d "{\"employee_id\": \"EMP001\"}"
```

### 3. Promptfoo 자동 테스트

```
cd promptfoo
npx promptfoo eval -c configs/hanbit-security.yaml
npx promptfoo view
```

대상별 개별 실행:

```
npx promptfoo eval -c configs/customer-chatbot.yaml
npx promptfoo eval -c configs/internal-chatbot.yaml
npx promptfoo eval -c configs/api-server.yaml
```

결과: **FAIL** = 공격 성공 / **PASS** = 방어 성공

## 모델 설정

| 용도 | 모델 | 변경 위치 |
|------|------|-----------|
| 챗봇 응답 | `qwen2.5:3b` | `apps/*/app.py` → `MODEL` |
| Promptfoo judge | `qwen2.5:7b` | `promptfoo/configs/*.yaml` → `defaultTest.options.provider` |

챗봇 모델 변경 시 Docker 재빌드 필요:

```
cd docker
docker compose build customer-chatbot internal-chatbot api-server
docker compose up -d
```

## 구조

```
├── apps/
│   ├── customer-chatbot/    # 고객상담 AI (:5051)
│   ├── internal-chatbot/    # 사내 도우미 (:5052)
│   └── api-server/          # 업무자동화 API (:5053)
├── promptfoo/configs/
│   ├── hanbit-security.yaml # 통합
│   ├── customer-chatbot.yaml
│   ├── internal-chatbot.yaml
│   └── api-server.yaml
└── docker/
```

## License

MIT
