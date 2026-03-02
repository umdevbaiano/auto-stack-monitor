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
  <strong>Stack robusta de Observabilidade padrão NOC (Network Operations Center) — Pronta para deploy em 1 clique.</strong><br>
  Uma infraestrutura imutável baseada em Docker Compose, unindo a resiliência do Zabbix, os dashboards dinâmicos do Grafana e integração de alertas instantâneos via Telegram.
</p>

---

## 🚀 Visão Geral

O **Auto-Stack Monitor** é uma solução de infraestrutura como código (IaC) focada em administradores de rede, Engenheiros de Confiabilidade (SRE) e Provedores de Serviço (ISP). O objetivo do projeto é transformar um ambiente vazio em uma **Central Operacional (NOC) ativa** em poucos minutos, oferecendo dashboards pré-configurados de IOPS de disco, topologia de rede e consumo computacional em tempo real, integrados diretamente ao seu smartphone.

### 🔥 Novidades desta Versão
- 📊 **Dashboards Premium Pré-Configurados**: Dispensa a importação manual de arquivos JSON. O Grafana é provisionado nativamente com 3 visões cirúrgicas: Visão Executiva NOC, Paging/Storage de Servidores Linux e Topologia de Rede Agregada.
- 📲 **Push Dinâmico para Telegram**: Script interno de automação (`telegram_alert.py`) que processa e despacha mensagens formatadas em HTML assim que um gatilho de alerta é ativado, garantindo notificações em tempo real.
- 🤖 **Assistente CLI Interativo**: Um utilitário de terminal (`onboarding.py`) que guia a configuração inicial do ambiente, ajustando variáveis de ambiente (`.env`), parâmetros do PostgreSQL e o perfil de implantação da infraestrutura humana.
- 🪟 **Suporte Multiplataforma**: Execução transparente em ambientes Unix (através de `setup.sh` e `Makefile`) e no Windows (via `start.bat`), automatizando rotinas complexas de PowerShell e Docker de forma agnóstica ao sistema operacional.
- 💣 **Simulador de Alta Carga (Caos)**: Inclui um contêiner dedicado (`simulated_host_01`) para a realização de testes de estresse. Valide suas políticas de alerta, SLAs e disparos de trigger submetendo o ambiente a cargas artificiais controladas.

---

## 📸 Screenshots

### 🖥️ Cluster Overview & Network (Premium)
![Cluster Overview](https://github.com/user-attachments/assets/bfcc4cce-0435-4638-b976-b22ba243f5c1)

### 📊 Deep Performance & Compute
![Deep Performance](https://github.com/user-attachments/assets/010d1c96-a70a-456a-918d-22073f2767ff)

### 📲 Alertas Telegram em Tempo Real
![Telegram Alerts](https://github.com/user-attachments/assets/d741270f-4cfe-4b6b-b89b-fe2038bf2ce2)

### 🗂️ Dashboards Disponíveis
![Dashboards](https://github.com/user-attachments/assets/7f006dd3-a055-456b-aa7b-168d05743799)

---

## ⚡ Instalação em 2 Passos

### 1. Inicie o Processo de Onboarding

O projeto traz um assistente de configuração automatizado e interativo.

**Para usuários Windows:**
Execute o arquivo `start.bat` na raiz do repositório. O assistente fará o download das bibliotecas Python necessárias, irá configurar as redes do Docker e realizará o deploy dos contêineres automaticamente.

**Para usuários Linux / macOS:**
Utilize o utilitário Make:
```bash
make up
```

*(O assistente de configuração solicitará a definição do seu perfil de uso - Homelab, ISP ou Enterprise. As suas credenciais e tokens de API serão armazenados de forma segura e exclusiva no seu arquivo `.env` local, não sendo rastreados pelo Git).*

### 2. Acesso aos Painéis e Credenciais

Após o término do deploy, os serviços estarão disponíveis nos seguintes endereços:

| Serviço          | Endereço                   | Usuário | Senha Padrão                     |
|------------------|----------------------------|---------|----------------------------------|
| **Zabbix UI**    | `http://localhost:8080`    | Admin   | zabbix *(Recomendamos alterar)*|
| **Grafana UI**   | `http://localhost:3000`    | admin   | Dinâmica (armazenada no `.env`)|

---

## 📲 Integração do Webhook do Telegram

A arquitetura de alertas está baseada na pasta `zabbix/alertscripts/telegram_alert.py`. Ela utiliza as regras de automação (Action) e auto-descoberta do Zabbix 7 para capturar eventos de mudança de estado (ex: `PROBLEM: CPU Overload` ou `RESOLVED: Ping Recovery`) e encaminhá-los para o chat da sua equipe ou dispositivo móvel.

### Como Configurar o Bot
1. Inicie uma conversa com o `@BotFather` no Telegram, envie o comando `/newbot` e guarde o seu **Token da API**.
2. Adicione o bot recém-criado em um grupo da sua equipe (ou em uma conversa particular), envie uma mensagem de teste e obtenha o `chat_id`.
3. Insira essas chaves quando o assistente `start.bat` ou `make up` solicitar. Caso prefira realizar a configuração manualmente, declare as variáveis equivalentes no seu arquivo `.env` na raiz do projeto. O container mapeará o webhook de forma transparente.

---

## 🗂 Estrutura Técnica de Diretórios

Organização do repositório:

```text
auto-stack-monitor/
├── docker-compose.yml           # Arquitetura Core (Zabbix Server, Grafana, PostgreSQL, NGINX)
├── start.bat                    # Entrypoint para plataforma Windows (PowerShell)
├── setup.sh                     # Entrypoint para ambientes Linux / macOS (POSIX)
├── Makefile                     # Atalhos de orquestração (make logs, make clean)
├── onboarding.py                # Utilitário CLI interativo para setup inicial
├── .env.example                 # Template de variáveis de ambiente
├── zabbix/
│   ├── alertscripts/            # Scripts Python de integração via Webhook
│   └── templates/               # Templates XML (Importação manual via Zabbix Frontend)
├── grafana/
│   └── provisioning/
│       ├── datasources/         # Conexão automática via Zabbix API (JSON-RPC)
│       └── dashboards/          # Arquivos JSON das visões NOC Premium
└── README.md
```

## 🛠 Comandos de Manutenção Clássicos

```bash
# Para remover o ambiente atual e realizar um build limpo
make clean
make build

# Para monitorar o fluxo de logs gerados pela API do Zabbix
make logs-zbx

# Para simular eventos críticos de infraestrutura
# Aciona o contêiner de simulação para forçar métricas altíssimas
docker exec simulated_host_01 [comandos_de_estresse_aqui] 
```

> **Autoria e Licenciamento:** MIT License. Este projeto consolida práticas de Infraestrutura como Código sob uma ótica de administração moderna de TI. Adapte as diretrizes de LLD e expanda os limites de telemetria livremente através dos painéis do Grafana Provisioning conforme a necessidade do seu data center.
