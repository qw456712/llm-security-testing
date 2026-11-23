@echo off
chcp 65001 >nul 2>&1

echo ============================================================
echo   LLM Security Lab - 실습 환경 종료
echo ============================================================
echo.

set "DOCKER_DIR=%~dp0docker"

echo [1/2] Docker 컨테이너 종료 중...
cd /d "%DOCKER_DIR%"
docker compose down
echo   [OK] 컨테이너 종료 완료
echo.

echo [2/2] Ollama 종료 중...
taskkill /IM ollama.exe /F >nul 2>&1
if not errorlevel 1 (
    echo   [OK] Ollama 종료 완료
) else (
    echo   [건너뜀] Ollama가 실행 중이지 않습니다
)
echo.

echo ============================================================
echo   [완료] LLM Security Lab이 종료되었습니다.
echo   다시 시작하려면 start.bat을 실행하세요.
echo ============================================================
echo.
pause
