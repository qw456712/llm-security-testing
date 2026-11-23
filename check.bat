@echo off
chcp 65001 >nul 2>&1

echo ============================================================
echo   LLM Security Lab - 상태 확인
echo ============================================================
echo.

:: Docker 확인
echo [Docker Desktop]
docker --version 2>nul
if errorlevel 1 (
    echo   상태: 미설치
) else (
    docker info >nul 2>&1
    if errorlevel 1 (
        echo   상태: 설치됨, 미실행
    ) else (
        echo   상태: 실행 중
    )
)
echo.

:: Ollama 확인
echo [Ollama]
ollama --version 2>nul
if errorlevel 1 (
    echo   상태: 미설치
) else (
    curl -sf http://localhost:11434 >nul 2>&1
    if not errorlevel 1 (
        echo   상태: 실행 중
        echo   모델 목록:
        ollama list 2>nul
    ) else (
        echo   상태: 설치됨, 미실행
    )
)
echo.

:: 컨테이너 상태
echo [Docker 컨테이너]
docker ps --filter "name=llm-lab" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>nul
if errorlevel 1 (
    echo   컨테이너가 실행 중이지 않습니다.
)
echo.

:: 서비스 접속 확인
echo [서비스 상태]

curl -sf http://localhost:5001/health >nul 2>&1
if not errorlevel 1 (
    echo   Dify API (localhost:5001):   OK
) else (
    echo   Dify API (localhost:5001):   접속 불가
)

curl -sf http://localhost:3000 >nul 2>&1
if not errorlevel 1 (
    echo   Dify Web (localhost:3000):   OK
) else (
    echo   Dify Web (localhost:3000):   접속 불가
)

curl -sf http://localhost:5050/health >nul 2>&1
if not errorlevel 1 (
    echo   FAQ 챗봇 (localhost:5050):       OK
) else (
    echo   FAQ 챗봇 (localhost:5050):       접속 불가
)

curl -sf http://localhost:5051/health >nul 2>&1
if not errorlevel 1 (
    echo   고객상담 AI (localhost:5051):    OK
) else (
    echo   고객상담 AI (localhost:5051):    접속 불가
)

curl -sf http://localhost:5052/health >nul 2>&1
if not errorlevel 1 (
    echo   사내 도우미 (localhost:5052):    OK
) else (
    echo   사내 도우미 (localhost:5052):    접속 불가
)

curl -sf http://localhost:5053/health >nul 2>&1
if not errorlevel 1 (
    echo   업무자동화 API (localhost:5053): OK
) else (
    echo   업무자동화 API (localhost:5053): 접속 불가
)

curl -sf http://localhost:11434 >nul 2>&1
if not errorlevel 1 (
    echo   Ollama (localhost:11434):        OK
) else (
    echo   Ollama (localhost:11434):        접속 불가
)

echo.

:: 디스크 사용량
echo [디스크 사용량]
docker system df 2>nul
echo.

echo ============================================================
echo   문제가 있다면 다음을 시도하세요:
echo     1. Docker Desktop 재시작
echo     2. stop.bat 실행 후 start.bat 재실행
echo     3. reset.bat으로 초기화
echo ============================================================
echo.
pause
