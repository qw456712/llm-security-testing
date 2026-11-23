@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion

echo ============================================================
echo   LLM Security Lab - 설치 프로그램
echo   LLM·SLM·AI 챗봇 보안 진단 통합 실습 환경
echo ============================================================
echo.

set "LAB_DIR=%~dp0"
set "DOCKER_DIR=%LAB_DIR%docker"
set "ERROR_COUNT=0"

:: ============================================================
:: 1. 시스템 요구사항 확인
:: ============================================================
echo [1/8] 시스템 요구사항 확인 중...

:: OS 확인
ver | findstr /i "10\." >nul 2>&1
if errorlevel 1 (
    echo   [경고] Windows 10 이상을 권장합니다.
)

:: RAM 확인
for /f "tokens=2 delims==" %%a in ('wmic computersystem get TotalPhysicalMemory /value 2^>nul') do set "RAM_BYTES=%%a"
set /a RAM_GB=%RAM_BYTES:~0,-9%
if %RAM_GB% LSS 16 (
    echo   [경고] RAM %RAM_GB%GB 감지. 최소 16GB를 권장합니다.
    echo   현재 환경에서는 성능이 제한될 수 있습니다.
) else (
    echo   [OK] RAM: %RAM_GB%GB
)

:: 디스크 여유 공간 확인
for /f "tokens=3" %%a in ('dir %LAB_DIR% 2^>nul ^| findstr /i "bytes free"') do set "FREE_SPACE=%%a"
echo   [OK] 시스템 요구사항 확인 완료
echo.

:: ============================================================
:: 2. Docker Desktop 확인
:: ============================================================
echo [2/8] Docker Desktop 확인 중...

docker --version >nul 2>&1
if errorlevel 1 (
    echo   [오류] Docker Desktop이 설치되어 있지 않습니다.
    echo.
    echo   Docker Desktop 설치 방법:
    echo   1. https://www.docker.com/products/docker-desktop/ 접속
    echo   2. "Download for Windows" 클릭하여 설치
    echo   3. 설치 후 PC 재시작
    echo   4. Docker Desktop 실행 후 이 스크립트를 다시 실행하세요
    echo.
    echo   [참고] WSL2가 필요합니다. Docker 설치 시 자동으로 안내됩니다.
    echo.
    set /a ERROR_COUNT+=1
    goto :check_errors
) else (
    for /f "tokens=*" %%v in ('docker --version 2^>nul') do echo   [OK] %%v
)

:: Docker 서비스 실행 확인
docker info >nul 2>&1
if errorlevel 1 (
    echo   [경고] Docker Desktop이 실행되고 있지 않습니다.
    echo   Docker Desktop을 시작합니다...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe" 2>nul
    echo   Docker Desktop이 시작될 때까지 최대 60초 대기합니다...
    set "DOCKER_WAIT=0"
    :wait_docker
    timeout /t 5 /nobreak >nul
    docker info >nul 2>&1
    if not errorlevel 1 goto :docker_ready
    set /a DOCKER_WAIT+=5
    if !DOCKER_WAIT! GEQ 60 (
        echo   [오류] Docker Desktop 시작에 실패했습니다.
        echo   수동으로 Docker Desktop을 시작한 뒤 다시 실행해주세요.
        set /a ERROR_COUNT+=1
        goto :check_errors
    )
    echo   대기 중... (!DOCKER_WAIT!초)
    goto :wait_docker
)
:docker_ready
echo   [OK] Docker Desktop 실행 중
echo.

:: ============================================================
:: 3. Docker Compose 확인
:: ============================================================
echo [3/8] Docker Compose 확인 중...
docker compose version >nul 2>&1
if errorlevel 1 (
    echo   [오류] Docker Compose를 사용할 수 없습니다.
    echo   Docker Desktop을 최신 버전으로 업데이트해주세요.
    set /a ERROR_COUNT+=1
    goto :check_errors
) else (
    for /f "tokens=*" %%v in ('docker compose version 2^>nul') do echo   [OK] %%v
)
echo.

:: ============================================================
:: 4. Ollama 확인
:: ============================================================
echo [4/8] Ollama 확인 중...

ollama --version >nul 2>&1
if errorlevel 1 (
    echo   [안내] Ollama가 설치되어 있지 않습니다.
    echo.
    echo   Ollama는 로컬 LLM 실행에 필요합니다.
    echo   설치 방법:
    echo   1. https://ollama.com/download 접속
    echo   2. "Download for Windows" 클릭하여 설치
    echo   3. 설치 후 이 스크립트를 다시 실행하세요
    echo.
    echo   [참고] Ollama 없이도 외부 API(OpenAI 등)로 실습 가능합니다.
    echo   Ollama 설치를 건너뛰고 계속하시겠습니까?
    echo.
    set /p SKIP_OLLAMA="계속 진행 (Y/N)? "
    if /i "!SKIP_OLLAMA!"=="N" goto :check_errors
    echo   Ollama 설치를 건너뜁니다. 나중에 설치할 수 있습니다.
) else (
    for /f "tokens=*" %%v in ('ollama --version 2^>nul') do echo   [OK] %%v

    :: 기본 모델 다운로드
    echo   기본 모델(qwen2.5:1.5b) 다운로드 확인 중...
    ollama list 2>nul | findstr /i "qwen2.5:1.5b" >nul 2>&1
    if errorlevel 1 (
        echo   기본 모델을 다운로드합니다. (약 1GB, 네트워크 속도에 따라 수 분 소요)
        echo.
        ollama pull qwen2.5:1.5b
        if errorlevel 1 (
            echo   [경고] 모델 다운로드에 실패했습니다. 나중에 수동으로 다운로드할 수 있습니다.
            echo   명령어: ollama pull qwen2.5:1.5b
        ) else (
            echo   [OK] 기본 모델 다운로드 완료
        )
    ) else (
        echo   [OK] 기본 모델 이미 설치됨
    )
)
echo.

:: ============================================================
:: 5. 환경 설정 파일 생성
:: ============================================================
echo [5/8] 환경 설정 파일 생성 중...

if not exist "%DOCKER_DIR%\.env" (
    copy "%DOCKER_DIR%\.env.example" "%DOCKER_DIR%\.env" >nul
    echo   [OK] .env 파일 생성 완료
    echo.
    echo   [선택] OpenAI API Key를 설정하시겠습니까?
    echo   (없어도 로컬 모델(Ollama)로 실습 가능합니다)
    echo.
    set /p SET_API="API Key 설정 (Y/N)? "
    if /i "!SET_API!"=="Y" (
        set /p API_KEY="OpenAI API Key 입력: "
        if not "!API_KEY!"=="" (
            echo OPENAI_API_KEY=!API_KEY!>> "%DOCKER_DIR%\.env"
            echo   [OK] API Key 설정 완료
        )
    )
) else (
    echo   [OK] .env 파일 이미 존재
)
echo.

:: ============================================================
:: 6. Docker 이미지 다운로드
:: ============================================================
echo [6/8] Docker 이미지 다운로드 중... (최초 실행 시 수 분 소요)
echo.

cd /d "%DOCKER_DIR%"
docker compose pull
if errorlevel 1 (
    echo.
    echo   [오류] Docker 이미지 다운로드에 실패했습니다.
    echo   네트워크 연결을 확인하고 다시 시도해주세요.
    set /a ERROR_COUNT+=1
    goto :check_errors
)
echo.
echo   [OK] Docker 이미지 다운로드 완료
echo.

:: ============================================================
:: 7. 커스텀 이미지 빌드
:: ============================================================
echo [7/8] 실습 앱 빌드 중...

docker compose build faq-chatbot customer-chatbot internal-chatbot api-server
if errorlevel 1 (
    echo   [경고] 실습 앱 빌드에 실패했습니다.
    echo   다시 시도: docker compose build
)
echo   [OK] 실습 앱 빌드 완료
echo.

:: ============================================================
:: 8. 바탕화면 바로가기 생성
:: ============================================================
echo [8/8] 바탕화면 바로가기 생성 중...

set "DESKTOP=%USERPROFILE%\Desktop"

:: start.bat 바로가기
echo Set oWS = WScript.CreateObject("WScript.Shell") > "%TEMP%\shortcut.vbs"
echo sLinkFile = "%DESKTOP%\LLM Security Lab - 시작.lnk" >> "%TEMP%\shortcut.vbs"
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%TEMP%\shortcut.vbs"
echo oLink.TargetPath = "%LAB_DIR%start.bat" >> "%TEMP%\shortcut.vbs"
echo oLink.WorkingDirectory = "%LAB_DIR%" >> "%TEMP%\shortcut.vbs"
echo oLink.Description = "LLM Security Lab 실습 환경 시작" >> "%TEMP%\shortcut.vbs"
echo oLink.Save >> "%TEMP%\shortcut.vbs"
cscript //nologo "%TEMP%\shortcut.vbs" >nul 2>&1
del "%TEMP%\shortcut.vbs" >nul 2>&1

:: stop.bat 바로가기
echo Set oWS = WScript.CreateObject("WScript.Shell") > "%TEMP%\shortcut.vbs"
echo sLinkFile = "%DESKTOP%\LLM Security Lab - 종료.lnk" >> "%TEMP%\shortcut.vbs"
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%TEMP%\shortcut.vbs"
echo oLink.TargetPath = "%LAB_DIR%stop.bat" >> "%TEMP%\shortcut.vbs"
echo oLink.WorkingDirectory = "%LAB_DIR%" >> "%TEMP%\shortcut.vbs"
echo oLink.Description = "LLM Security Lab 실습 환경 종료" >> "%TEMP%\shortcut.vbs"
echo oLink.Save >> "%TEMP%\shortcut.vbs"
cscript //nologo "%TEMP%\shortcut.vbs" >nul 2>&1
del "%TEMP%\shortcut.vbs" >nul 2>&1

echo   [OK] 바탕화면 바로가기 생성 완료
echo.

:check_errors
if %ERROR_COUNT% GTR 0 (
    echo ============================================================
    echo   [실패] 설치 중 %ERROR_COUNT%개의 오류가 발생했습니다.
    echo   위의 오류 메시지를 확인하고 조치 후 다시 실행해주세요.
    echo ============================================================
) else (
    echo ============================================================
    echo   [완료] LLM Security Lab 설치가 완료되었습니다!
    echo.
    echo   시작 방법:
    echo     1. 바탕화면의 "LLM Security Lab - 시작" 바로가기 실행
    echo     또는
    echo     2. start.bat 실행
    echo.
    echo   접속 주소:
    echo     Dify:             http://localhost:3000
    echo     FAQ 챗봇:         http://localhost:5050
    echo     고객상담 AI:      http://localhost:5051
    echo     사내 도우미:      http://localhost:5052
    echo     업무자동화 API:   http://localhost:5053
    echo.
    echo   Dify 초기 로그인:
    echo     이메일: admin@llm-lab.local
    echo     비밀번호: admin123 (최초 로그인 시 설정)
    echo ============================================================
)

echo.
pause
