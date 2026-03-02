#!/bin/bash
# =============================================================================
# Auto-Stack Monitor — NOC Simulator (Carga Global)
# Força limites arquitetônicos do host hospedeiro virtual (Zabbix Agent)
# para atestar Plotting massivo nos novos Dashboards do Grafana.
# =============================================================================

echo "=========================================="
echo " ☢️ Iniciando Simulação de Estresse Global"
echo "=========================================="

echo "[*] Instalando pacotes base bzip2 e wget no conteiner..."
apt-get update -qq >/dev/null
apt-get install -yqq bzip2 wget >/dev/null

# 1. CPU
echo "[*] Alocando Core CPU (bzip2 stress)..."
for i in {1..2}; do
    while true; do dd if=/dev/urandom bs=1M count=50 2>/dev/null | bzip2 -9 > /dev/null; done &
done

# 2. IOPS / Disk
echo "[*] Forçando Gargalo de I/O em Read/Write (dd loops)..."
while true; do 
    dd if=/dev/zero of=/tmp/io_teste_stress bs=1M count=200 2>/dev/null
    dd if=/tmp/io_teste_stress of=/dev/null bs=1M 2>/dev/null
done &

# 3. Memory (RAM Allocation via TempFS)
echo "[*] Esgotando reserva de Memória RAM em /dev/shm..."
dd if=/dev/zero of=/dev/shm/ram_fill_stress bs=1M count=1024 2>/dev/null &

# 4. Tráfego de Rede (Heavy Download Layer)
echo "[*] Direcionando pacotes de tráfego Ethernet contínuo..."
while true; do
    # Tenta puxar de origens rápidas nulas para simular tráfego de interface
    wget -qO- https://speed.hetzner.de/100MB.bin > /dev/null || sleep 1
done &

echo ""
echo "🔥 Todos os theads de caos disparados! (Em background)"
echo "O Zabbix Agent está coletando anomalias extremas."
