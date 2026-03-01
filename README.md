# 🖥️ Auto-Stack Monitor

<p align="center">
  <img src="https://img.shields.io/badge/Zabbix-7.0_LTS-red?style=for-the-badge&logo=zabbix&logoColor=white" />
  <img src="https://img.shields.io/badge/Grafana-Latest-orange?style=for-the-badge&logo=grafana&logoColor=white" />
  <img src="https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white" />
  <img src="https://img.shields.io/badge/Python-3.x-3776AB?style=for-the-badge&logo=python&logoColor=white" />
  <img src="https://img.shields.io/badge/Telegram-Alerts-26A5E4?style=for-the-badge&logo=telegram&logoColor=white" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" />
</p>

<p align="center">
  <strong>Stack completo de monitoramento open source — pronto em 1 comando.</strong><br>
  Zabbix + Grafana + Alertas Telegram via Docker Compose.
</p>

---

## 🚀 O que é isso?

**Auto-Stack Monitor** é um projeto open source que sobe automaticamente um ambiente completo de monitoramento de infraestrutura com:

- **Zabbix 7.0 LTS** — coleta de métricas, triggers e gestão de hosts
- **Grafana** — dashboards visuais com plugin Zabbix pré-configurado
- **Alertas Telegram** — notificações em tempo real quando algo vai mal
- **Docker Compose** — tudo isolado, portável e reproduzível
- **Setup automatizado** — 3 perguntas e você está monitorando

> Ideal para **NOC**, **sysadmins**, **analistas de redes**, **ISPs** e qualquer profissional que precisa de monitoramento sem gastar dias configurando.

---

## 📋 Pré-requisitos

| Ferramenta         | Versão mínima | Como instalar                                    |
|--------------------|---------------|--------------------------------------------------|
| Docker Engine      | 24.x+         | [docs.docker.com](https://docs.docker.com/engine/install/) |
| Docker Compose     | v2.x+         | Incluído no Docker Desktop / plugin no Linux     |
| Python 3           | 3.8+          | `apt install python3` / `brew install python3`   |
| curl               | qualquer      | Pré-instalado na maioria dos sistemas            |
| jq                 | qualquer      | `apt install jq` / `brew install jq`             |
| Bot Telegram       | —             | Crie em [@BotFather](https://t.me/BotFather)     |

---

## ⚡ Instalação em 3 Passos

### 1. Clone o repositório

```bash
git clone https://github.com/seu-usuario/auto-stack-monitor.git
cd auto-stack-monitor
```

### 2. Execute o setup

```bash
chmod +x setup.sh
./setup.sh
```

O script vai perguntar apenas 3 coisas:

```
[?] Token do seu Telegram Bot → 123456789:AABB...
[?] Telegram Chat ID          → -100987654321
[?] IP do primeiro host       → 192.168.1.10
```

### 3. Acesse as interfaces

| Serviço          | URL                        | Usuário | Senha (padrão)         |
|------------------|----------------------------|---------|------------------------|
| Zabbix Frontend  | http://localhost:8080      | Admin   | zabbix ← **troque!**  |
| Grafana          | http://localhost:3000      | admin   | salvo no `.env`        |

> ✅ Você receberá uma mensagem no Telegram confirmando que o stack está ativo.

---

## 🗂️ Estrutura do Projeto

```
auto-stack-monitor/
├── docker-compose.yml           # Stack completo (Zabbix + Grafana + PostgreSQL)
├── setup.sh                     # Script interativo e idempotente
├── Makefile                     # Comandos de conveniência
├── .env.example                 # Template de variáveis (copie para .env)
├── .gitignore
│
├── zabbix/
│   ├── alertscripts/
│   │   └── telegram_alert.py    # Script de alerta via Telegram Bot API
│   └── templates/               # Templates XML para importar no Zabbix
│
├── grafana/
│   └── provisioning/
│       ├── datasources/
│       │   └── zabbix.yml       # Datasource Zabbix pré-configurado
│       └── dashboards/
│           ├── dashboards.yml   # Provider de dashboards
│           └── linux-overview.json  # Dashboard Linux Servers
│
└── README.md
```

---

## 🔧 Comandos Make

```bash
make up           # Setup completo interativo
make start        # Sobe containers sem setup
make down         # Para o stack
make restart      # Reinicia todos os serviços
make logs         # Logs em tempo real
make logs-zbx     # Logs do Zabbix Server
make status       # Status dos containers
make test-tg      # Envia mensagem de teste ao Telegram
make clean        # Remove containers/imagens (preserva dados)
make hard-reset   # ⚠ Apaga TUDO incluindo volumes
```

---

## 📡 Adicionando Hosts para Monitorar

### Via Zabbix API (automatizado)

```bash
# Edite o .env com as variáveis do novo host
FIRST_HOST_IP=192.168.1.20
FIRST_HOST_NAME=servidor-nginx-01

# Reexecute o setup (é idempotente — não quebra o que já existe)
./setup.sh
```

### Via Interface Web (manual)

1. Acesse `http://localhost:8080` → Login `Admin / zabbix`
2. **Configuration** → **Hosts** → **Create host**
3. Preencha: hostname, IP, porta `10050`
4. Na aba **Templates**, adicione `Linux by Zabbix agent`
5. Clique **Add**

> 💡 O Zabbix Agent deve estar instalado no host remoto. Veja abaixo.

### Instalar Zabbix Agent no host remoto

```bash
# Ubuntu/Debian
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-1+ubuntu22.04_all.deb
dpkg -i zabbix-release_7.0-1+ubuntu22.04_all.deb
apt update && apt install zabbix-agent2

# Configure o agent
echo "Server=IP_DO_SEU_SERVIDOR_ZABBIX" >> /etc/zabbix/zabbix_agent2.conf
systemctl enable --now zabbix-agent2
```

---

## 📲 Configurando Alertas no Telegram

### 1. Criar o Bot

1. Abra o Telegram e fale com [@BotFather](https://t.me/BotFather)
2. Envie `/newbot` e siga as instruções
3. Copie o **token** gerado (ex: `123456789:AABBccddeeff...`)

### 2. Obter o Chat ID

**Para grupos:**
1. Adicione o bot ao grupo
2. Envie qualquer mensagem no grupo
3. Acesse: `https://api.telegram.org/bot<TOKEN>/getUpdates`
4. O `chat.id` aparecerá negativo (ex: `-100123456789`)

**Para usuário direto:**
1. Inicie conversa com o bot
2. Acesse a URL acima — `chat.id` será positivo

### 3. Configurar no Zabbix (Media Type)

1. **Administration** → **Media types** → **Telegram**
2. Atualize o parâmetro `BOT_TOKEN` com seu token
3. Em **Users** → **Admin** → **Media**, adicione com o Chat ID em "Send to"
4. Em **Actions** → **Trigger actions**, vincule ao Media Type Telegram

### 4. Personalizar Mensagens

Edite o Action em **Trigger actions** com macros Zabbix:

```
Subject: {TRIGGER.STATUS}: {TRIGGER.NAME}

Body:
Host: {HOST.NAME} ({HOST.IP})
Problema: {TRIGGER.NAME}
Severidade: {TRIGGER.SEVERITY}
Tempo: {EVENT.DATE} {EVENT.TIME}
```

---

## 🎛️ Personalizando o Stack

### Alterar senhas

Edite o `.env` e execute:

```bash
make restart
```

### Trocar a versão do Zabbix

```bash
# .env
ZABBIX_VERSION=6.4-latest   # ou 7.0-latest
```

### Adicionar mais dashboards

Coloque arquivos `.json` em `grafana/provisioning/dashboards/` — serão carregados automaticamente em até 30 segundos.

### Escalar pollers do Zabbix

```bash
# .env
ZBX_STARTPOLLERS=10
ZBX_CACHESIZE=256M
```

---

## 🐛 Troubleshooting

**Containers não sobem:**
```bash
docker compose logs -f          # Ver erros
docker compose down && make up  # Reiniciar do zero
```

**Grafana não conecta ao Zabbix:**
- Verifique se `zabbix-frontend` está healthy: `docker compose ps`
- No datasource, a URL deve ser `http://zabbix-frontend:8080/api_jsonrpc.php` (nome do container)

**Telegram não envia mensagens:**
```bash
make test-tg          # Teste rápido
# Verifique TELEGRAM_BOT_TOKEN e TELEGRAM_CHAT_ID no .env
```

**Porta em uso:**
```bash
# .env — mude as portas
ZBX_FRONTEND_PORT=8081
GF_PORT=3001
```

---

## 🏗️ Arquitetura

```
                    ┌─────────────────┐
                    │   Você / NOC    │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
     ┌────────▼──────┐ ┌─────▼──────┐ ┌───▼──────────┐
     │ Zabbix :8080  │ │Grafana:3000│ │   Telegram   │
     │  (Frontend)   │ │(Dashboards)│ │   (Alertas)  │
     └───────┬───────┘ └─────┬──────┘ └───▲──────────┘
             │               │             │
     ┌───────▼───────────────▼─────────────┤
     │         Zabbix Server :10051        │
     │         (coleta + triggers)         │
     └───────┬─────────────────────────────┘
             │
     ┌───────▼─────────┐
     │  PostgreSQL 15  │
     │  (banco dados)  │
     └─────────────────┘
             ▲
     ┌───────┴──────────────────────────────┐
     │  Zabbix Agent :10050  (hosts)        │
     │  Linux servers, routers, switches... │
     └──────────────────────────────────────┘
```

---

## 📈 Roadmap

- [ ] Template XML para dispositivos de rede (MikroTik, Cisco, Ubiquiti)
- [ ] Dashboard para NOC com mapa de hosts
- [ ] Script de backup automático do banco de dados
- [ ] Integração com Slack além do Telegram
- [ ] Suporte a SNMP traps

---

## 🤝 Contribuindo

1. Fork o projeto
2. Crie sua branch: `git checkout -b feat/nova-feature`
3. Commit: `git commit -m 'feat: adiciona suporte a X'`
4. Push: `git push origin feat/nova-feature`
5. Abra um Pull Request

---

## 👨‍💻 Autor

**Samuel Miranda**
Network Security Engineer & Founder — [Vetta Hub Tecnologia](https://vettahub.com.br)
2 anos operando Zabbix e Grafana em produção para ISPs na Bahia.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Samuel_Miranda-0077B5?style=flat&logo=linkedin)](https://linkedin.com/in/seu-perfil)
[![GitHub](https://img.shields.io/badge/GitHub-auto--stack--monitor-181717?style=flat&logo=github)](https://github.com/seu-usuario/auto-stack-monitor)

---

## 📄 Licença

Este projeto está sob a licença **MIT**. Veja [LICENSE](LICENSE) para mais detalhes.

---

<p align="center">
  <sub>Samuel Miranda</sub>
</p>
