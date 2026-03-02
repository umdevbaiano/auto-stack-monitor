# 🖥️ Auto-Stack Monitor (NOC Premium Edition)

<p align="center">
  <img src="https://img.shields.io/badge/Zabbix-7.0_LTS-red?style=for-the-badge&logo=zabbix&logoColor=white" />
  <img src="https://img.shields.io/badge/Grafana-10.x-orange?style=for-the-badge&logo=grafana&logoColor=white" />
  <img src="https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white" />
  <img src="https://img.shields.io/badge/Python-3.x-3776AB?style=for-the-badge&logo=python&logoColor=white" />
  <img src="https://img.shields.io/badge/Telegram-Alerts-26A5E4?style=for-the-badge&logo=telegram&logoColor=white" />
  <img src="https://img.shields.io/badge/OS-Windows_|_Linux-green?style=for-the-badge" />
</p>

<p align="center">
  <strong>Stack robusto de Observabilidade inspirado em NOCs de Big Techs — Pronto em 1 clique.</strong><br>
  Deploy imutável através de Docker Compose unindo o core do Zabbix, a beleza do Grafana e Webhooks para o Telegram.
</p>

---

## 🚀 Visão Geral

O **Auto-Stack Monitor** é um pipeline de provisionamento infraestrutural focado em administradores de rede, SREs e Provedores de Serviço (ISP). Ele configura um ambiente cego e vazio e o transforma numa **Central Operacional (NOC) ativa**, embutindo gráficos dinâmicos de Network IOPS, uso de Storage e Desempenho Computacional conectando um webhook autônomo diretamente ao seu Smartphone.

### 🔥 Features Exclusivas desta Versão
- 📊 **Dashboards Premium Pre-Provisionados**: Não perca tempo montando painéis JSON! O Grafana já inicializa com 3 visões cirúrgicas (Visão Executiva NOC, Paging & Storage Linux, e Topologia de Rede Aggregada).
- 📲 **Telegram Push Dinâmico**: Script interno (`telegram_alert.py`) de envio imediato de HTML para o Telegram. Sem atrasos. Relate o caos *no segundo* que o load bater no teto!
- 🤖 **Assistente CLI Interativo**: Scripts inteligentes guiam a construção da infraestrutura do zero (`onboarding.py`), preparando as pontes de rede, banco PostgreSQL e profiles de deploy de maneira humanizada.
- 🪟 **Dual-Platform (Cross OS)**: Suporte 100% nativo com wrappers em Bash (`setup.sh`/`Makefile`) para mundos Unix e Batch puro (`start.bat`) com injeção PowerShell para usuários Windows. Não sofra com incompatibilidades!
- 💣 **Simulador de Desastres Interno**: Conta com o comando de stress e simulação nativos do contêiner `simulated_host_01`. Crie caos artificial e ateste que seus SLAs e Alarmes estão vivos.

---

## ⚡ Instalação em 2 Passos

### 1. Inicialize a Central de Comando (Onboarding)

O projeto possui um Wizard interativo robusto e inofensivo.

**Para Windows:**
Dê um duplo-clique no arquivo `start.bat` no diretório raiz do clone. Ele instalará dependências da UI, construirá a ponte docker de forma visual e chamará os containers.

**Para Linux / macOS:**
Apenas acione pelo Make:
```bash
make up
```

*(O `onboarding.py` exibirá opções de painéis baseados na sua persona - ISP, Homelab, Enterprise - e embutirá os dados sensíveis APENAS no seu arquivo `.env` local, não sendo jamais transportado pelo git).*

### 2. Painéis e Credenciais Padrões

| Serviço          | Endereço                   | Usuário | Senha Padrão                     |
|------------------|----------------------------|---------|----------------------------------|
| **Zabbix UI**    | `http://localhost:8080`    | Admin   | zabbix *(Troque)*               |
| **Grafana UI**   | `http://localhost:3000`    | admin   | Lida no setup (`.env`)          |

---

## 📲 Integração de Telegram em Tempo Real

Na pasta `zabbix/alertscripts/telegram_alert.py`, a mágica engatilha direto do coração do Zabbix 7 via Macros Automáticas de Descoberta. O Zabbix dispara `PROBLEM: CPU Overload` ou `RESOLVED: Ping Recovery` e nosso script converte em lindas caixas de chat de Smartphone.

### Configurar Bot
1. Chame o `@BotFather` no Telegram, crie `/newbot` e guarde seu **Token API**.
2. Abra seu próprio Bot ou adicione num Grupo, digite um texto para abri-lo, e busque seu `chat_id`.
3. Adicione estas chaves no wizard durante o `start.bat`, ou simplesmente cole na mão dentro do seu `.env` invisível na pasta raiz! O docker engine do backend fará o resto da amarração.

---

## 🗂 Estrutura Técnica de Diretórios

```text
auto-stack-monitor/
├── docker-compose.yml           # Core Stack (Zabbix Server, Grafana, PostgreSQL, NGINX)
├── start.bat                    # Start Windows / Powershell Bridge
├── setup.sh                     # Start Linux / MacOS POSIX
├── Makefile                     # Atalhos de Build (make logs, make clean)
├── onboarding.py                # Setup Assistido Mágico (Rich UI)
├── .env.example                 # Environment Blueprint
├── zabbix/
│   ├── alertscripts/            # Telegram Engine e Bot Pushers
│   └── templates/               # (Importáveis XML via interface Zabbix)
├── grafana/
│   └── provisioning/
│       ├── datasources/         # Datasource Zabbix JSON-RPC Automático
│       └── dashboards/          # Painéis NOC JSON Idempotentes Exclusivos
└── README.md
```

## 🛠 Comandos Adicionais Interessantes

```bash
# Derrube e reinicie com tabula rasa
make clean
make build

# Assista somente os logs de requisição da Zabbix API
make logs-zbx

# Chame a dor (Disparador de Gatilhos Naturais via Simulated Host)
# Aloca um conteneir Zabbix Agent estressado para validar as Regras
docker exec simulated_host_01 [comandos de stress cpu] 
```

> **Autoria e Licenciamento:** MIT License. Este repositório foca em infraestrutura como código visando observabilidade corporativa. Adapte e escale as métricas Low-level e LLD livremente mediante os arquivos do Grafana Provisioning.
