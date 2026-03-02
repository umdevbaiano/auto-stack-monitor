#!/usr/bin/env python3
# =============================================================================
# onboarding.py — Auto-Stack Monitor CLI Setup
#
# Interação avançada de terminal (TUI) para configurar alertas via Telegram e
# direcionar o template Zabbix correto.
# =============================================================================

import os
import sys
import time
import requests

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.prompt import Prompt, Confirm
    from rich.progress import Progress, SpinnerColumn, TextColumn
    from rich.align import Align
except ImportError:
    print("A biblioteca 'rich' é necessária para executar o onboarding. Instale com:")
    print("  pip install rich requests")
# ── Prevenções de encoding de ambiente Windows ──────────────
if sys.platform == "win32":
    # Força alteração da Code Page do terminal para UTF-8 (65001)
    os.system("chcp 65001 >nul 2>&1")
    try:
        if hasattr(sys.stdout, 'reconfigure'):
            sys.stdout.reconfigure(encoding='utf-8')
            sys.stderr.reconfigure(encoding='utf-8')
    except Exception:
        pass

console = Console()

BANNER = """
 █████╗ ██╗   ██╗████████╗██████╗         
██╔══██╗██║   ██║╚══██╔══╝██╔══██╗        
███████║██║   ██║   ██║   ██║  ██║        
██╔══██║██║   ██║   ██║   ██║  ██║        
██║  ██║╚██████╔╝   ██║   ██████╔╝        
╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═════╝         
                                          
███████╗████████╗███████╗██████╗          
██╔════╝╚══██╔══╝██╔════╝██╔══██╗         
███████╗   ██║   █████╗  ██████╔╝         
╚════██║   ██║   ██╔══╝  ██╔═══╝          
███████║   ██║   ███████╗██║              
╚══════╝   ╚═╝   ╚══════╝╚═╝              
"""

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def show_banner():
    clear_screen()
    console.print(Align.center(f"[bold cyan]{BANNER}[/bold cyan]"))
    console.print(Align.center("[bold magenta]Made by: Samuel Miranda[/bold magenta]\n"))

def load_env():
    env_vars = {}
    if os.path.exists('.env'):
        with open('.env', 'r', encoding='utf-8') as f:
            for line in f:
                if line.strip() and not line.startswith('#'):
                    if '=' in line:
                        key, val = line.strip().split('=', 1)
                        env_vars[key] = val
    return env_vars

def save_env(vars_dict, original_lines):
    with open('.env', 'w', encoding='utf-8') as f:
        # Tenta preservar a estrutura original, apenas atualizando chaves conhecidas
        updated_keys = set()
        for line in original_lines:
            stripped = line.strip()
            if stripped and not stripped.startswith('#') and '=' in stripped:
                key, _ = stripped.split('=', 1)
                if key in vars_dict:
                    f.write(f"{key}={vars_dict[key]}\n")
                    updated_keys.add(key)
                else:
                    f.write(line)
            else:
                f.write(line)
        
        # Adiciona as que não existiam no arquivo original
        for k, v in vars_dict.items():
            if k not in updated_keys:
                f.write(f"{k}={v}\n")

def section_telegram(env_vars):
    console.print(Panel("[bold yellow]Sessão 1 — Configuração de Alertas (Telegram)[/bold yellow]"))
    console.print("O Auto-Stack possui integração 100% nativa de desastres conectada ao Telegram.")
    console.print("Sinta-se livre para não preencher isso agora (apenas pressione ENTER).\n")
    
    current_token = env_vars.get("TELEGRAM_BOT_TOKEN", "")
    current_chat = env_vars.get("TELEGRAM_CHAT_ID", "")
    
    if current_token == "123456789:AABBCCDDEEFFaabbccddeeff-exemplo": current_token = ""
    if current_chat == "-100123456789": current_chat = ""

    token = Prompt.ask("[cyan]Token da API do Bot (Criado via BotFather)[/cyan]", default=current_token)
    chat_id = Prompt.ask("[cyan]Chat ID do destinatário (Seu ID ou ID do Grupo)[/cyan]", default=current_chat)

    if token: env_vars["TELEGRAM_BOT_TOKEN"] = token
    if chat_id: env_vars["TELEGRAM_CHAT_ID"] = chat_id
    
    console.print("[bold green]✔ Configurações baseadas salvas localmente![/bold green]")

def section_profile(env_vars):
    console.print("\n")
    console.print(Panel("[bold yellow]Sessão 2 — Onboarding de Uso (Perfil do Cliente)[/bold yellow]"))
    console.print("O Auto-Stack possui templates predefinidos. Identifique seu perfil de uso preferencial:\n")
    
    options = {
        "1": "Provedor de Internet (ISP) — Foco em uptime de links, latência, visibilidade BGP",
        "2": "Empresa / Corporativo — Foco em servidores, serviços Windows/Linux e SLA crítico",
        "3": "Home Lab — Foco em recursos locais, Docker containers do lab, Hypervisors (Proxmox)",
        "4": "Personalizado / Advanced — Configuração 100% manual e limpa"
    }

    for k, v in options.items():
        console.print(f"  [bold cyan]{k}.[/bold cyan] {v}")
    
    console.print()
    choice = Prompt.ask("Qual template se encaixa no seu uso atual?", choices=["1", "2", "3", "4"], default="2")
    
    env_vars["MONITOR_PROFILE"] = choice
    
    console.print()
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        transient=True,
    ) as progress:
        progress.add_task(description="[bold magenta]Provisionando arquitetura requisitada...[/bold magenta]", total=None)
        time.sleep(2)

    if choice == "1":
        profile_name = "Provedor de Internet (ISP)"
        config_status = "Templates de ICMP High Frequency, SNMP estendido e rotas provisionados para prioridade no Zabbix."
        pending = "Adicionar os IPs físicos de Roteadores de Borda (Edge) e Switches Layer 3 manualmente no painel web."
    elif choice == "2":
        profile_name = "Empresa / Corporativo"
        config_status = "Dashboards NOC (visuais executivas) cravadas. Template de bancos (PostgreSQL, MySQL) e OS ativados."
        pending = "Instalar o Zabbix Agent2 nos servidores de produção e configurar a macro URL do Telegram."
    elif choice == "3":
        profile_name = "Home Lab"
        config_status = "Gráficos com viés educacional setados. Descoberta de containers (LLD) injetada na API."
        pending = "Habilitar monitoramento passivo e garantir privilégios de ROOT para o App acessar docker.sock."
    else:
        profile_name = "Personalizado"
        config_status = "O projeto foi construído limpo, entregando apenas o Docker Compose subjacente funcional."
        pending = "Você é o mestre de obras. Importe templates XML e popule JSONs no Grafana manualmente."

    return profile_name, config_status, pending

def summary(profile_name, config_status, pending):
    console.print("\n")
    panel_content = f"""[bold green]✅ Arquitetura de Observabilidade Mapeada![/bold green]

[bold]💼 Perfil Selecionado:[/bold] {profile_name}

🗂️  [bold cyan]O que foi configurado agora:[/bold cyan]
 • Variáveis do Telegram Bot registradas em `.env` e persistidas
 • {config_status}

⚠️  [bold yellow]O que ainda está pendente (Steps Finais):[/bold yellow]
 • {pending}
 • Realizar bypass da senha padrão `zabbix` no Frontend Web.

🚀 [bold magenta]Próximos passos:[/bold magenta]
Execute no terminal:
   $ [bold cyan]docker compose up -d[/bold cyan]   (Para subir os contêineres Zabbix e Grafana)
   $ [bold cyan]make logs[/bold cyan]              (Para assistir a mágica acontecer)

   [link=http://localhost:3000]Grafana Web[/link] (Localhost:3000)
   [link=http://localhost:8080]Zabbix Web[/link]  (Localhost:8080)
"""
    console.print(Panel(panel_content, title="Resumo das Operações", expand=False, border_style="green"))

def main():
    show_banner()
    
    original_lines = []
    if os.path.exists('.env'):
        with open('.env', 'r', encoding='utf-8') as f:
            original_lines = f.readlines()
    
    env_vars = load_env()
    
    section_telegram(env_vars)
    profile_name, config_status, pending = section_profile(env_vars)
    
    save_env(env_vars, original_lines)
    summary(profile_name, config_status, pending)
    
    console.print("\n🏁 Onboarding finalizado. Divirta-se. \n")

if __name__ == "__main__":
    main()
