# =============================================================================
# Makefile — auto-stack-monitor
# Comandos de conveniência para gerenciar o stack
# =============================================================================

.PHONY: up down restart logs status setup clean hard-reset help

COMPOSE = docker compose
ENV_FILE = .env

# ── Alvo padrão ──────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  auto-stack-monitor — Comandos disponíveis:"
	@echo ""
	@echo "  make up          → Sobe o stack completo (após o onboarding)"
	@echo "  make start       → Sobe containers sem setup interativo"
	@echo "  make down        → Para e remove containers"
	@echo "  make restart     → Reinicia todos os serviços"
	@echo "  make logs        → Exibe logs em tempo real"
	@echo "  make logs-zbx    → Logs apenas do Zabbix Server"
	@echo "  make logs-gf     → Logs apenas do Grafana"
	@echo "  make status      → Status dos containers"
	@echo "  make onboarding  → Executa a TUI interativa de setup (Python)"
	@echo "  make clean       → Remove containers e imagens (preserva volumes)"
	@echo "  make hard-reset  → ⚠ Remove TUDO incluindo volumes (dados perdidos)"
	@echo "  make test-tg     → Envia mensagem de teste ao Telegram"
	@echo "  make simulate    → 🧪 Simula um host linux com pico de CPU (NOC Test)"
	@echo "  make env         → Cria .env a partir de .env.example"
	@echo ""

# ── Setup completo ────────────────────────────────────────────────────────
up: env onboarding
	$(COMPOSE) up -d

# ── Subir sem setup interativo ────────────────────────────────────────────
start: env
	$(COMPOSE) up -d
	@echo "✔ Stack iniciado"
	@echo "  Zabbix  → http://localhost:$$(grep ZBX_FRONTEND_PORT $(ENV_FILE) | cut -d= -f2)"
	@echo "  Grafana → http://localhost:$$(grep GF_PORT $(ENV_FILE) | cut -d= -f2)"

# ── Parar ─────────────────────────────────────────────────────────────────
down:
	$(COMPOSE) down

# ── Reiniciar ─────────────────────────────────────────────────────────────
restart:
	$(COMPOSE) restart

# ── Logs ──────────────────────────────────────────────────────────────────
logs:
	$(COMPOSE) logs -f --tail=100

logs-zbx:
	$(COMPOSE) logs -f --tail=100 zabbix-server

logs-gf:
	$(COMPOSE) logs -f --tail=100 grafana

# ── Status ────────────────────────────────────────────────────────────────
status:
	$(COMPOSE) ps

# ── Setup isolado ─────────────────────────────────────────────────────────
onboarding:
	@pip install -r requirements.txt > /dev/null 2>&1
	@python onboarding.py

# ── Criar .env ────────────────────────────────────────────────────────────
env:
	@if [ ! -f $(ENV_FILE) ]; then \
		cp .env.example $(ENV_FILE); \
		echo "✔ .env criado — edite as senhas antes de continuar"; \
	fi

# ── Limpar (preserva volumes) ─────────────────────────────────────────────
clean:
	$(COMPOSE) down --rmi local
	@echo "✔ Containers e imagens locais removidos (volumes preservados)"

# ── Reset total ───────────────────────────────────────────────────────────
hard-reset:
	@echo "⚠ ATENÇÃO: Isso vai apagar TODOS os dados (banco, dashboards, etc.)"
	@echo "   Pressione Ctrl+C para cancelar ou Enter para continuar..."
	@read _
	$(COMPOSE) down -v --rmi local
	@echo "✔ Reset completo realizado"

# ── Teste Telegram ────────────────────────────────────────────────────────
test-tg:
	@source $(ENV_FILE) && \
	curl -s \
	  "https://api.telegram.org/bot$${TELEGRAM_BOT_TOKEN}/sendMessage" \
	  -d "chat_id=$${TELEGRAM_CHAT_ID}" \
	  -d "parse_mode=HTML" \
	  -d "text=🧪 <b>Teste Auto-Stack Monitor</b>%0AMensagem de teste enviada via Makefile." \
	| python3 -c "import sys,json; r=json.load(sys.stdin); print('✔ Enviado!' if r.get('ok') else '✘ Erro: '+str(r))"

# ── Simulação NOC (Teste em Alta Escala) ──────────────────────────────────
simulate:
	@echo "🧪 Subindo host simulado (simulated-host-01) injetando carga..."
	$(COMPOSE) -f docker-compose-simulator.yml up -d
	@echo "⏳ Espalhando telemetria..."
	@sleep 5
	@docker cp simulate_noc.sh simulated_host_01:/tmp/simulate_noc.sh
	@docker exec -d simulated_host_01 bash /tmp/simulate_noc.sh
	@echo "✔ Chaos Engineering iniciado! Acesse o Novo Grafana (Linux Overview / Network) para verificar a plotagem sistêmica de CPU, RAM, IOPS e Rede."

simulate-stop:
	@echo "🛑 Encerrando tráfego de teste..."
	$(COMPOSE) -f docker-compose-simulator.yml down
	@echo "✔ Testes desligados com sucesso."
