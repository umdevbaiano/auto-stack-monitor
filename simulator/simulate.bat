@echo off
setlocal
title Auto-Stack Monitor - Simulador NOC

echo ====================================================
echo   Auto-Stack NOC - Teste de Estresse Global
echo ====================================================
echo.

echo [1/3] Subindo host simulado (simulated-host-01) injetando carga...
docker compose -f docker-compose-simulator.yml up -d

echo.
echo [2/3] Aguardando o agent respirar (5s)...
ping 127.0.0.1 -n 6 > nul

echo.
echo [3/3] Injetando script de carga Global NOC (CPU/RAM/IOPs/Net)...
docker cp simulate_noc.sh simulated_host_01:/tmp/simulate_noc.sh
docker exec -d simulated_host_01 bash /tmp/simulate_noc.sh

echo.
echo ====================================================
echo  [🔥] Chaos Engineering iniciado em background!
echo.
echo  Acesse o Novo Grafana (Linux Overview / Network) 
echo  para verificar a plotagem sistemica dos limites de 
echo  CPU, Paginaçao RAM, IOPS e Redes.
echo ====================================================
echo.
echo Para desligar o motor de simulacao, use:
echo docker compose -f docker-compose-simulator.yml down
echo.

pause
