#!/usr/bin/env bash
# =============================================================================
# auto-stack-monitor — setup.sh
# Script de setup interativo e idempotente
# Autor: Samuel Miranda — Vetta Hub Tecnologia
# =============================================================================

set -euo pipefail

# ── Cores ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ── Helpers ────────────────────────────────────────────────────────────────
log()     { echo -e "${GREEN}[✔]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[✘]${NC} $*" >&2; exit 1; }
step()    { echo -e "\n${BLUE}${BOLD}▶ $*${NC}"; }
ask()     { echo -e "${CYAN}[?]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"

# ── Banner ─────────────────────────────────────────────────────────────────
print_banner() {
  echo -e "${BOLD}${CYAN}"
  cat << 'EOF'
  ╔═══════════════════════════════════════════════════════╗
  ║          AUTO-STACK MONITOR  v1.0.0                   ║
  ║     Zabbix + Grafana + Telegram — by Vetta Hub        ║
  ╚═══════════════════════════════════════════════════════╝
EOF
  echo -e "${NC}"
}

# ── Pré-requisitos ─────────────────────────────────────────────────────────
check_deps() {
  step "Verificando dependências..."
  local missing=()

  for cmd in docker curl python3 jq; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    else
      log "$cmd encontrado"
    fi
  done

  # Docker Compose (plugin v2 ou standalone v1)
  if docker compose version &>/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
    log "docker compose (plugin v2)"
  elif command -v docker-compose &>/dev/null; then
    COMPOSE_CMD="docker-compose"
    log "docker-compose (standalone)"
  else
    missing+=("docker-compose")
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    error "Dependências faltando: ${missing[*]}\nInstale-as antes de continuar."
  fi
}

# ── Arquivo .env ───────────────────────────────────────────────────────────
setup_env() {
  step "Configurando variáveis de ambiente..."

  if [[ ! -f "${ENV_FILE}" ]]; then
    cp "${SCRIPT_DIR}/.env.example" "${ENV_FILE}"
    log ".env criado a partir de .env.example"
  else
    warn ".env já existe — preservando configurações existentes"
  fi

  # ── Perguntas interativas ────────────────────────────────────────────────
  echo ""
  echo -e "${BOLD}Responda as perguntas abaixo (Enter para usar o padrão):${NC}"
  echo ""

  # Token do Telegram
  local current_token
  current_token=$(grep "^TELEGRAM_BOT_TOKEN=" "${ENV_FILE}" | cut -d= -f2)
  if [[ "$current_token" == *"exemplo"* ]] || [[ -z "$current_token" ]]; then
    ask "Token do seu Telegram Bot (obtenha em @BotFather):"
    read -r -p "  → " tg_token
    if [[ -n "$tg_token" ]]; then
      sed -i "s|^TELEGRAM_BOT_TOKEN=.*|TELEGRAM_BOT_TOKEN=${tg_token}|" "${ENV_FILE}"
      log "Telegram Bot Token configurado"
    else
      warn "Token do Telegram não definido — alertas não funcionarão"
    fi
  else
    log "Telegram Bot Token já configurado"
  fi

  # Chat ID do Telegram
  local current_chat
  current_chat=$(grep "^TELEGRAM_CHAT_ID=" "${ENV_FILE}" | cut -d= -f2)
  if [[ "$current_chat" == *"123456"* ]] || [[ -z "$current_chat" ]]; then
    ask "Telegram Chat ID (grupo começa com -100, usuário é positivo):"
    read -r -p "  → " tg_chat
    if [[ -n "$tg_chat" ]]; then
      sed -i "s|^TELEGRAM_CHAT_ID=.*|TELEGRAM_CHAT_ID=${tg_chat}|" "${ENV_FILE}"
      log "Telegram Chat ID configurado"
    else
      warn "Chat ID não definido — alertas não funcionarão"
    fi
  else
    log "Telegram Chat ID já configurado"
  fi

  # IP do primeiro host
  local current_host_ip
  current_host_ip=$(grep "^FIRST_HOST_IP=" "${ENV_FILE}" | cut -d= -f2)
  if [[ -z "$current_host_ip" ]]; then
    ask "IP do primeiro host a monitorar (opcional, pode pular):"
    read -r -p "  → " first_ip
    if [[ -n "$first_ip" ]]; then
      sed -i "s|^FIRST_HOST_IP=.*|FIRST_HOST_IP=${first_ip}|" "${ENV_FILE}"

      ask "Nome desse host (ex: servidor-web-01):"
      read -r -p "  → " first_name
      first_name="${first_name:-host-01}"
      sed -i "s|^FIRST_HOST_NAME=.*|FIRST_HOST_NAME=${first_name}|" "${ENV_FILE}"
      log "Primeiro host configurado: ${first_name} (${first_ip})"
    else
      warn "Nenhum host adicional configurado — você pode adicionar depois"
    fi
  else
    log "Primeiro host já configurado: ${current_host_ip}"
  fi

  # Gerar senhas fortes se ainda estão como padrão
  generate_if_default "POSTGRES_PASSWORD" "Z@bbix_S3cur3_P@ss!"
  generate_if_default "GF_ADMIN_PASSWORD" "Gr@fan@_S3cur3!"
}

generate_if_default() {
  local key="$1" default_val="$2"
  local current
  current=$(grep "^${key}=" "${ENV_FILE}" | cut -d= -f2)
  if [[ "$current" == "$default_val" ]]; then
    local new_pass
    new_pass=$(python3 -c "import secrets,string; \
      chars=string.ascii_letters+string.digits+'@#!'; \
      print(''.join(secrets.choice(chars) for _ in range(20)))")
    sed -i "s|^${key}=.*|${key}=${new_pass}|" "${ENV_FILE}"
    log "Senha gerada automaticamente para ${key}"
  fi
}

# ── Subir stack ────────────────────────────────────────────────────────────
start_stack() {
  step "Subindo o stack Docker..."
  cd "${SCRIPT_DIR}"
  $COMPOSE_CMD up -d --build
  log "Containers iniciados"
}

# ── Aguardar Zabbix ────────────────────────────────────────────────────────
wait_for_zabbix() {
  step "Aguardando Zabbix Frontend ficar disponível..."
  local port
  port=$(grep "^ZBX_FRONTEND_PORT=" "${ENV_FILE}" | cut -d= -f2 || echo "8080")
  local max_tries=60 tries=0

  while [[ $tries -lt $max_tries ]]; do
    if curl -sf "http://localhost:${port}/" -o /dev/null 2>/dev/null; then
      log "Zabbix Frontend disponível em http://localhost:${port}"
      return 0
    fi
    tries=$((tries + 1))
    echo -ne "\r  Aguardando... ${tries}/${max_tries}s"
    sleep 2
  done
  echo ""
  error "Zabbix Frontend não respondeu após ${max_tries} tentativas. Verifique: docker logs zbx_frontend"
}

# ── Configurar via Zabbix API ──────────────────────────────────────────────
configure_zabbix_api() {
  step "Configurando Zabbix via API..."

  source "${ENV_FILE}"

  local api_url="http://localhost:${ZBX_FRONTEND_PORT:-8080}/api_jsonrpc.php"
  local admin_user="${ZBX_API_USER:-Admin}"
  local admin_pass="${ZBX_API_PASSWORD:-zabbix}"

  # Auth token
  local auth_response
  auth_response=$(curl -sf -X POST "${api_url}" \
    -H "Content-Type: application/json" \
    -d "{
      \"jsonrpc\": \"2.0\",
      \"method\": \"user.login\",
      \"params\": {
        \"username\": \"${admin_user}\",
        \"password\": \"${admin_pass}\"
      },
      \"id\": 1
    }" 2>/dev/null) || true

  local auth_token
  auth_token=$(echo "$auth_response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('result',''))" 2>/dev/null || echo "")

  if [[ -z "$auth_token" ]]; then
    warn "Não foi possível autenticar na API Zabbix (credenciais padrão podem ter mudado)"
    warn "Execute manualmente: python3 zabbix/scripts/configure_api.py"
    return 0
  fi

  log "Autenticado na Zabbix API"

  # Configurar Telegram Media Type (webhook)
  configure_telegram_mediatype "$api_url" "$auth_token"

  # Adicionar primeiro host se configurado
  if [[ -n "${FIRST_HOST_IP:-}" ]] && [[ -n "${FIRST_HOST_NAME:-}" ]]; then
    add_host "$api_url" "$auth_token" "$FIRST_HOST_NAME" "$FIRST_HOST_IP"
  fi

  # Logout
  curl -sf -X POST "${api_url}" \
    -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"method\":\"user.logout\",\"params\":[],\"auth\":\"${auth_token}\",\"id\":99}" \
    -o /dev/null || true
}

configure_telegram_mediatype() {
  local api_url="$1" token="$2"
  source "${ENV_FILE}"

  if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]] || [[ "${TELEGRAM_BOT_TOKEN}" == *"exemplo"* ]]; then
    warn "Token do Telegram não configurado — pulando configuração do Media Type"
    return 0
  fi

  # Ler o script do webhook
  local webhook_script
  webhook_script=$(cat "${SCRIPT_DIR}/zabbix/alertscripts/telegram_webhook.js" 2>/dev/null || echo "")

  if [[ -z "$webhook_script" ]]; then
    warn "Script do webhook Telegram não encontrado"
    return 0
  fi

  # Criar/atualizar Media Type Telegram
  local create_response
  create_response=$(curl -sf -X POST "${api_url}" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json
payload = {
  'jsonrpc': '2.0',
  'method': 'mediatype.create',
  'params': {
    'name': 'Telegram',
    'type': 4,
    'exec_path': 'telegram_alert.py',
    'parameters': [
      {'name': 'BOT_TOKEN', 'value': '${TELEGRAM_BOT_TOKEN}'},
      {'name': 'CHAT_ID', 'value': '${TELEGRAM_CHAT_ID}'}
    ]
  },
  'auth': '${token}',
  'id': 10
}
print(json.dumps(payload))
")" 2>/dev/null) || true

  log "Media Type Telegram configurado"
}

add_host() {
  local api_url="$1" token="$2" hostname="$3" ip="$4"

  # Obter ID do grupo "Linux servers"
  local group_response
  group_response=$(curl -sf -X POST "${api_url}" \
    -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"method\":\"hostgroup.get\",
        \"params\":{\"filter\":{\"name\":[\"Linux servers\"]}},
        \"auth\":\"${token}\",\"id\":20}" 2>/dev/null) || true

  local group_id
  group_id=$(echo "$group_response" | python3 -c \
    "import sys,json; r=json.load(sys.stdin)['result']; print(r[0]['groupid'] if r else '2')" 2>/dev/null || echo "2")

  # Obter ID do template Linux by Zabbix agent
  local tpl_response
  tpl_response=$(curl -sf -X POST "${api_url}" \
    -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"method\":\"template.get\",
        \"params\":{\"filter\":{\"name\":[\"Linux by Zabbix agent\"]}},
        \"auth\":\"${token}\",\"id\":21}" 2>/dev/null) || true

  local tpl_id
  tpl_id=$(echo "$tpl_response" | python3 -c \
    "import sys,json; r=json.load(sys.stdin)['result']; print(r[0]['templateid'] if r else '')" 2>/dev/null || echo "")

  local templates_json="[]"
  if [[ -n "$tpl_id" ]]; then
    templates_json="[{\"templateid\":\"${tpl_id}\"}]"
  fi

  local add_response
  add_response=$(curl -sf -X POST "${api_url}" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json
payload = {
  'jsonrpc': '2.0',
  'method': 'host.create',
  'params': {
    'host': '${hostname}',
    'interfaces': [{
      'type': 1, 'main': 1, 'useip': 1,
      'ip': '${ip}', 'dns': '', 'port': '10050'
    }],
    'groups': [{'groupid': '${group_id}'}],
    'templates': json.loads('${templates_json}')
  },
  'auth': '${token}',
  'id': 22
}
print(json.dumps(payload))
")" 2>/dev/null) || true

  local host_id
  host_id=$(echo "$add_response" | python3 -c \
    "import sys,json; r=json.load(sys.stdin); print(r.get('result',{}).get('hostids',['?'])[0])" 2>/dev/null || echo "")

  if [[ -n "$host_id" ]] && [[ "$host_id" != "?" ]]; then
    log "Host '${hostname}' (${ip}) adicionado com ID ${host_id}"
  else
    warn "Não foi possível adicionar host '${hostname}' — pode já existir ou houve erro"
  fi
}

# ── Sumário final ──────────────────────────────────────────────────────────
print_summary() {
  source "${ENV_FILE}"
  echo ""
  echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${GREEN}║     🚀  STACK ATIVO COM SUCESSO!             ║${NC}"
  echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${BOLD}Zabbix Frontend${NC}  → http://localhost:${ZBX_FRONTEND_PORT:-8080}"
  echo -e "  ${BOLD}Grafana${NC}          → http://localhost:${GF_PORT:-3000}"
  echo ""
  echo -e "  ${BOLD}Zabbix Login${NC}"
  echo -e "    Usuário : ${ZBX_API_USER:-Admin}"
  echo -e "    Senha   : ${ZBX_API_PASSWORD:-zabbix}  ${YELLOW}← TROQUE!${NC}"
  echo ""
  echo -e "  ${BOLD}Grafana Login${NC}"
  echo -e "    Usuário : ${GF_ADMIN_USER:-admin}"
  echo -e "    Senha   : ${GF_ADMIN_PASSWORD}  ${YELLOW}← salva no .env${NC}"
  echo ""
  echo -e "  ${BOLD}Logs${NC}  → ${CYAN}docker compose logs -f${NC}"
  echo -e "  ${BOLD}Parar${NC} → ${CYAN}docker compose down${NC}"
  echo ""

  if [[ -n "${TELEGRAM_BOT_TOKEN:-}" ]] && [[ "${TELEGRAM_BOT_TOKEN}" != *"exemplo"* ]]; then
    echo -e "  ${GREEN}✔ Telegram configurado${NC}"
  else
    echo -e "  ${YELLOW}⚠ Telegram NÃO configurado — edite .env e reexecute ./setup.sh${NC}"
  fi
  echo ""
}

# ── Testar alerta Telegram ─────────────────────────────────────────────────
test_telegram() {
  step "Testando alerta Telegram..."
  source "${ENV_FILE}"

  if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]] || [[ "${TELEGRAM_BOT_TOKEN}" == *"exemplo"* ]]; then
    warn "Token do Telegram não configurado — pulando teste"
    return 0
  fi

  local response
  response=$(curl -sf \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "parse_mode=HTML" \
    -d "text=🟢 <b>Auto-Stack Monitor</b>%0AStack de monitoramento iniciado com sucesso!%0A%0A📡 Zabbix + Grafana + Telegram ativos." \
    2>/dev/null) || true

  if echo "$response" | grep -q '"ok":true'; then
    log "Mensagem de teste enviada ao Telegram!"
  else
    warn "Falha ao enviar mensagem de teste. Verifique token e chat_id no .env"
    warn "Resposta: $response"
  fi
}

# ── Main ───────────────────────────────────────────────────────────────────
main() {
  print_banner
  check_deps
  setup_env
  start_stack
  wait_for_zabbix
  configure_zabbix_api
  test_telegram
  print_summary
}

main "$@"
