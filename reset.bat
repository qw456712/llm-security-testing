@echo off
chcp 65001 >nul 2>&1

echo ============================================================
echo   LLM Security Lab - 실습 데이터 초기화
echo ============================================================
echo.
echo   [주의] 이 작업은 다음 데이터를 삭제합니다:
echo     - Dify에서 생성한 모든 앱 및 대화 내역
echo     - Knowledge Base 데이터
echo     - 데이터베이스 (PostgreSQL, Redis, Weaviate)
echo.
echo   사용자 작업 결과(user_workspace)는 보존됩니다.
echo.

set /p CONFIRM="정말 초기화하시겠습니까? (YES 입력): "
if not "%CONFIRM%"=="YES" (
    echo   초기화가 취소되었습니다.
    pause
    exit /b 0
)

set "DOCKER_DIR=%~dp0docker"

echo.
echo [1/3] 컨테이너 종료 중...
cd /d "%DOCKER_DIR%"
docker compose down
echo   [OK] 컨테이너 종료 완료

echo.
echo [2/3] 데이터 볼륨 삭제 중...
docker volume rm llm-lab-postgres llm-lab-redis llm-lab-weaviate llm-lab-dify-storage 2>nul
echo   [OK] 볼륨 삭제 완료

echo.
echo [3/4] 환경 재시작 중...
docker compose up -d
echo   [OK] 환경 재시작 완료

echo.
echo [4/4] DB 마이그레이션 중...
timeout /t 15 /nobreak >nul
docker exec llm-lab-dify-api flask db upgrade >nul 2>&1
echo   [OK] DB 마이그레이션 완료

echo.
echo ============================================================
echo   [완료] 실습 데이터가 초기화되었습니다.
echo   Dify에 다시 접속하여 초기 설정을 진행하세요.
echo   접속 주소: http://localhost:3000
echo ============================================================
echo.
pause
