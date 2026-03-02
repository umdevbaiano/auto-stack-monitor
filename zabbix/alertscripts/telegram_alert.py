#!/usr/bin/env python3
# =============================================================================
# telegram_alert.py — Zabbix AlertScript para notificações no Telegram
#
# Uso pelo Zabbix:
#   Campo "Send to"   → {TELEGRAM_CHAT_ID}       (configurado no usuário)
#   Campo "Subject"   → {TRIGGER.STATUS}: {TRIGGER.NAME}
#   Campo "Message"   → corpo completo da mensagem
#
# Zabbix chama: telegram_alert.py <send_to> <subject> <body>
#
# Autor: Samuel Miranda — Vetta Hub Tecnologia
# =============================================================================

import sys
import os
import json
import urllib.request
import urllib.parse
import urllib.error
import logging
from datetime import datetime

# ── Configuração ──────────────────────────────────────────────────────────
BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "")
API_BASE  = f"https://api.telegram.org/bot{BOT_TOKEN}"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("/tmp/telegram_alert.log"),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger(__name__)


# ── Emojis por severidade / status ───────────────────────────────────────
STATUS_EMOJI = {
    "problem":  "🔴",
    "resolved": "🟢",
    "update":   "🟡",
    "disaster": "🚨",
    "high":     "🔴",
    "average":  "🟠",
    "warning":  "🟡",
    "info":     "🔵",
    "unknown":  "⚪",
}


def get_emoji(subject: str) -> str:
    """Retorna emoji baseado no status/severidade extraído do subject."""
    subject_lower = subject.lower()
    for key, emoji in STATUS_EMOJI.items():
        if key in subject_lower:
            return emoji
    return "📢"


def format_message(subject: str, body: str) -> str:
    """
    Formata a mensagem em HTML para o Telegram com visual avançado NOC.
    """
    emoji = get_emoji(subject)
    now   = datetime.now().strftime("%d/%m/%Y %H:%M:%S")

    def escape_html(t: str) -> str:
        return t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

    subject_esc = escape_html(subject)
    
    formatted_body = []
    for line in body.splitlines():
        line_esc = escape_html(line)
        # Destacar keywords que o Zabbix comumente envia
        if line_esc.startswith("Host:") or line_esc.startswith("Servidor:"):
            formatted_body.append(f"🖥️ <b>{line_esc}</b>")
        elif line_esc.startswith("Severity:") or line_esc.startswith("Severidade:"):
            formatted_body.append(f"⚠️ <b>{line_esc}</b>")
        elif line_esc.startswith("Problem started") or line_esc.startswith("Problema iniciado"):
            formatted_body.append(f"🕒 <i>{line_esc}</i>")
        elif line_esc.startswith("Problem name:") or line_esc.startswith("Problema:"):
            formatted_body.append(f"🎯 <b>{line_esc}</b>")
        elif line_esc.startswith("Event ID:"):
            formatted_body.append(f"🏷️ <code>{line_esc}</code>")
        else:
            formatted_body.append(line_esc)

    body_final = "\n".join(formatted_body)
    
    links = (
        '🔗 <a href="http://localhost:3000/dashboards">Grafana Dashboards</a> | '
        '<a href="http://localhost:8080/zabbix.php?action=problem.view">Zabbix Problems</a>'
    )

    return (
        f"{emoji} <b>{subject_esc}</b>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━\n"
        f"{body_final}\n"
        f"━━━━━━━━━━━━━━━━━━━━━━\n"
        f"{links}\n"
        f"🕐 <i>{now} | Auto-Stack Monitor NOC</i>"
    )


def send_message(chat_id: str, text: str, retries: int = 3) -> bool:
    """
    Envia mensagem via Telegram Bot API com retry automático.
    Retorna True se enviado com sucesso.
    """
    if not BOT_TOKEN:
        log.error("TELEGRAM_BOT_TOKEN não definido")
        return False

    url  = f"{API_BASE}/sendMessage"
    data = json.dumps({
        "chat_id":    chat_id,
        "text":       text,
        "parse_mode": "HTML",
        "disable_web_page_preview": True,
    }).encode("utf-8")

    headers = {"Content-Type": "application/json; charset=utf-8"}

    for attempt in range(1, retries + 1):
        try:
            req      = urllib.request.Request(url, data=data, headers=headers)
            response = urllib.request.urlopen(req, timeout=15)
            result   = json.loads(response.read().decode("utf-8"))

            if result.get("ok"):
                log.info(f"Mensagem enviada ao chat {chat_id} (tentativa {attempt})")
                return True
            else:
                log.warning(f"API retornou erro: {result.get('description', 'desconhecido')}")

        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", errors="replace")
            log.error(f"HTTPError {e.code} na tentativa {attempt}: {body}")
        except urllib.error.URLError as e:
            log.error(f"URLError na tentativa {attempt}: {e.reason}")
        except Exception as e:
            log.error(f"Erro inesperado na tentativa {attempt}: {e}")

    return False


def main() -> int:
    """
    Ponto de entrada chamado pelo Zabbix.
    Argumentos: <chat_id_ou_send_to> <subject> <body>
    """
    if len(sys.argv) < 4:
        log.error(f"Uso: {sys.argv[0]} <chat_id> <subject> <body>")
        log.error(f"Argumentos recebidos: {sys.argv}")
        return 1

    chat_id = sys.argv[1].strip()
    subject = sys.argv[2].strip()
    body    = sys.argv[3].strip()

    log.info(f"Alerta recebido — Chat: {chat_id} | Subject: {subject[:60]}")

    # Suporte a múltiplos destinatários separados por vírgula
    recipients = [c.strip() for c in chat_id.split(",") if c.strip()]

    if not recipients:
        log.error("Nenhum chat_id válido fornecido")
        return 1

    text    = format_message(subject, body)
    success = True

    for recipient in recipients:
        if not send_message(recipient, text):
            log.error(f"Falha ao enviar para {recipient}")
            success = False

    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
