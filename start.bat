@echo off
setlocal
title Auto-Stack Monitor (NOC Edition) - Setup

echo ====================================================
echo   Auto-Stack Monitor - Inicializador Windows (.bat)
echo ====================================================
echo.

:: Verifica se o Python esta instalado
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [X] ERRO: Python nao encontrado no PATH. 
    echo Instale o Python 3.8+ e tente novamente.
    pause
    exit /b 1
)

:: Verifica se o Docker esta rodando
docker ps >nul 2>&1
if %errorlevel% neq 0 (
    echo [X] ERRO: Docker Desktop nao esta rodando. 
    echo Inicie o Docker e tente novamente!
    pause
    exit /b 1
)

echo [1/3] Preparando dependencias da CLI grafica...
python -m pip install -r requirements.txt >nul 2>&1

echo.
echo [2/3] Iniciando o fluxo de Onboarding (Python TUI)...
python onboarding.py

if %errorlevel% neq 0 (
    echo.
    echo [X] O onboarding foi cancelado ou falhou.
    pause
    exit /b 1
)

echo.
echo [3/3] Subindo ambiente NOC Monitor (Zabbix + Grafana)...
docker compose up -d

echo.
echo ====================================================
echo  [OK] Auto-Stack Monitor iniciado com sucesso!
echo.
echo  Grafana Web : http://localhost:3000
echo  Zabbix Web  : http://localhost:8080
echo ====================================================
echo.
pause
