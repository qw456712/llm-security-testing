# 오류 해결 가이드

## 설치 관련

### Docker Desktop이 설치되지 않음
```
[오류] Docker Desktop이 설치되어 있지 않습니다.
```
**해결:**
1. https://www.docker.com/products/docker-desktop/ 에서 다운로드
2. 설치 시 "Use WSL 2 instead of Hyper-V" 옵션 선택
3. 설치 완료 후 PC 재시작
4. Docker Desktop 실행 후 `install.bat` 재실행

### WSL2 관련 오류
```
WSL 2 installation is incomplete
```
**해결:**
1. 관리자 권한 PowerShell 실행
2. `wsl --install` 실행
3. PC 재시작
4. Docker Desktop 재시작

### Docker Desktop이 시작되지 않음
```
docker: error during connect
```
**해결:**
1. 작업 관리자에서 Docker Desktop 프로세스 종료
2. Docker Desktop 재시작
3. 시스템 트레이에서 Docker 아이콘이 "Running" 상태인지 확인
4. 안 되면 PC 재시작 후 Docker Desktop 실행

---

## 실행 관련

### 포트 충돌
```
Bind for 0.0.0.0:3000: address already in use
```
**해결:**
1. 충돌 프로세스 확인: `netstat -ano | findstr :3000`
2. 해당 프로세스 종료 또는
3. `docker/.env` 파일에서 `DIFY_WEB_PORT=3001` 등으로 변경
4. 변경 후 `http://localhost:3001`로 접속

### 컨테이너가 계속 재시작됨
```
llm-lab-dify-api ... Restarting
```
**해결:**
1. 로그 확인: `docker logs llm-lab-dify-api`
2. 주로 DB 연결 문제 — PostgreSQL이 먼저 준비되어야 함
3. `stop.bat` 실행 후 30초 대기, `start.bat` 재실행
4. 계속되면 `reset.bat`으로 초기화

### Ollama 연결 실패 (Dify에서)
```
Connection refused: host.docker.internal:11434
```
**해결:**
1. Ollama가 실행 중인지 확인: `ollama list`
2. Ollama 서비스 재시작: `ollama serve`
3. Windows 방화벽에서 11434 포트 허용
4. Dify 모델 설정에서 URL을 `http://host.docker.internal:11434`로 확인

### Dify 접속 시 빈 화면
**해결:**
1. Dify API가 준비될 때까지 1~2분 대기
2. `check.bat` 실행하여 서비스 상태 확인
3. 브라우저 캐시 삭제 후 재접속
4. `http://localhost:3000` 직접 접속 시도

---

## Promptfoo 관련

### npx promptfoo 실행 불가
```
'npx' is not recognized
```
**해결:**
1. Node.js 설치: https://nodejs.org/ (LTS 버전)
2. 설치 후 새 터미널 열기
3. `npx promptfoo --version` 확인

### Red Team 테스트에서 API 키 오류
```
Error: API key required for red team generation
```
**해결:**
- Red Team 플러그인 중 일부는 외부 LLM API가 필요합니다.
- `basic-security.yaml`은 API 없이도 실행 가능
- Red Team 전체 테스트는 OpenAI API Key 설정 필요

---

## 성능 관련

### Ollama 응답이 매우 느림
**원인:** CPU Only 환경에서 큰 모델 실행
**해결:**
1. 더 작은 모델 사용: `ollama pull qwen2.5:0.5b`
2. GPU가 있으면 NVIDIA 드라이버 최신 버전 설치
3. 다른 무거운 프로그램 종료

### 메모리 부족
**해결:**
1. Docker Desktop > Settings > Resources > Memory를 8GB로 설정
2. 불필요한 프로그램 종료
3. Ollama에서 작은 모델 사용
4. 최소 16GB RAM 권장

---

## 초기화 및 복구

### 모든 것을 처음부터 다시 시작하고 싶음
```
1. stop.bat 실행
2. uninstall.bat 실행
3. install.bat 실행
```

### Dify 비밀번호를 잊었음
```
1. reset.bat 실행 (모든 데이터 초기화됨)
2. Dify에 다시 접속하여 초기 설정
```
