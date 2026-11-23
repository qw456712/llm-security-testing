@echo off
chcp 65001 >nul 2>&1
setlocal

echo ============================================================
echo   LLM Security Lab - 실습 환경 시작
echo ============================================================
echo.

set "LAB_DIR=%~dp0"
set "DOCKER_DIR=%LAB_DIR%docker"

:: Docker 실행 확인
docker info >nul 2>&1
if errorlevel 1 (
    echo [안내] Docker Desktop을 시작합니다...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe" 2>nul
    echo Docker Desktop이 준비될 때까지 대기 중...
    :wait_docker
    timeout /t 5 /nobreak >nul
    docker info >nul 2>&1
    if errorlevel 1 goto :wait_docker
    echo [OK] Docker Desktop 준비 완료
    echo.
)

:: Ollama 시작
echo [1/4] Ollama 시작 중...
tasklist /FI "IMAGENAME eq ollama.exe" 2>nul | findstr /i "ollama.exe" >nul 2>&1
if errorlevel 1 (
    where ollama >nul 2>&1
    if not errorlevel 1 (
        start /min "" ollama serve
        timeout /t 3 /nobreak >nul
        echo   [OK] Ollama 시작됨
    ) else (
        echo   [건너뜀] Ollama가 설치되어 있지 않습니다
    )
) else (
    echo   [OK] Ollama 이미 실행 중
)
echo.

:: Docker Compose 시작
echo [2/4] Docker 컨테이너 시작 중...
cd /d "%DOCKER_DIR%"
docker compose up -d
if errorlevel 1 (
    echo.
    echo [오류] 컨테이너 시작에 실패했습니다.
    echo check.bat을 실행하여 상태를 확인하세요.
    pause
    exit /b 1
)
echo.

:: DB 마이그레이션 (최초 설치 시 필요)
echo [3/4] DB 마이그레이션 확인 중...
docker exec llm-lab-dify-api flask db upgrade >nul 2>&1
echo   [OK] DB 마이그레이션 완료
echo.

:: 서비스 준비 대기
echo [4/4] 서비스 준비 대기 중...
set "WAIT=0"
:wait_ready
timeout /t 3 /nobreak >nul
curl -sf http://localhost:5001/health >nul 2>&1
if not errorlevel 1 goto :ready
set /a WAIT+=3
if %WAIT% GEQ 90 (
    echo   [경고] 서비스 시작이 지연되고 있습니다.
    echo   브라우저에서 직접 접속을 시도해보세요.
    goto :ready
)
echo   대기 중... (%WAIT%초)
goto :wait_ready

:ready
echo.
echo ============================================================
echo   [완료] LLM Security Lab이 시작되었습니다!
echo.
echo   접속 주소:
echo     Dify:             http://localhost:3000
echo     FAQ 챗봇:         http://localhost:5050
echo     고객상담 AI:      http://localhost:5051
echo     사내 도우미:      http://localhost:5052
echo     업무자동화 API:   http://localhost:5053
echo     Ollama:           http://localhost:11434
echo.
echo   종료: stop.bat 실행 또는 바탕화면 "LLM Security Lab - 종료"
echo ============================================================

:: 브라우저 자동 열기
start "" "http://localhost:3000"

echo.
pause
