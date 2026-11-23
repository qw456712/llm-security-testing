@echo off
chcp 65001 >nul 2>&1

echo ============================================================
echo   LLM Security Lab - 실습 환경 삭제
echo ============================================================
echo.
echo   [주의] 이 작업은 다음을 삭제합니다:
echo     - 모든 Docker 컨테이너
echo     - 모든 Docker 이미지 (llm-lab 관련)
echo     - 모든 데이터 볼륨
echo     - 바탕화면 바로가기
echo.
echo   Docker Desktop과 Ollama는 삭제되지 않습니다.
echo.

set /p CONFIRM="정말 삭제하시겠습니까? (YES 입력): "
if not "%CONFIRM%"=="YES" (
    echo   삭제가 취소되었습니다.
    pause
    exit /b 0
)

set "DOCKER_DIR=%~dp0docker"

echo.
echo [1/4] 컨테이너 종료 및 삭제 중...
cd /d "%DOCKER_DIR%"
docker compose down --rmi local --volumes --remove-orphans 2>nul
echo   [OK] 컨테이너 삭제 완료

echo.
echo [2/4] 데이터 볼륨 삭제 중...
docker volume rm llm-lab-postgres llm-lab-redis llm-lab-weaviate llm-lab-dify-storage 2>nul
echo   [OK] 볼륨 삭제 완료

echo.
echo [3/4] Docker 이미지 정리 중...
docker image prune -f >nul 2>&1
echo   [OK] 이미지 정리 완료

echo.
echo [4/4] 바탕화면 바로가기 삭제 중...
del "%USERPROFILE%\Desktop\LLM Security Lab - 시작.lnk" 2>nul
del "%USERPROFILE%\Desktop\LLM Security Lab - 종료.lnk" 2>nul
echo   [OK] 바로가기 삭제 완료

echo.
echo ============================================================
echo   [완료] LLM Security Lab이 삭제되었습니다.
echo.
echo   이 폴더(llm-security-lab)는 수동으로 삭제하세요.
echo   Docker Desktop/Ollama는 별도로 삭제하세요.
echo ============================================================
echo.
pause
