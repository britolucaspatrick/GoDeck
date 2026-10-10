# 🚀 GoDeck Monorepo

**GoDeck** transforma seu smartphone Android ou iOS em um painel de macros, atalhos e trackpad de baixíssima latência para desktop (estilo Stream Deck), utilizando **Flutter** no aplicativo mobile e **Go (Golang)** no daemon do servidor host.

---

## 📁 Estrutura do Monorepo

```text
GoDeck/
├── .github/
│   └── workflows/
│       ├── app-ci.yml          # CI do Flutter (análise, testes e build APK)
│       └── server-ci.yml       # CI do Go (testes e cross-compilação)
├── docs/
│   └── protocol-spec.md        # Especificação formal do protocolo JSON sobre WebSocket
├── scripts/
│   └── setup.sh                # Verificação de ambiente e setup local
├── server/                     # GoDeck Server / Daemon (Go)
│   ├── cmd/godeck/main.go      # Ponto de entrada do executável Go
│   ├── internal/
│   │   ├── config/             # Configurações de porta e detecção de IPs de rede
│   │   ├── input/              # Emulação de teclado/atalhos/mouse no SO
│   │   └── websocket/          # Hub WebSocket, clientes e dispatcher de eventos
│   ├── go.mod
│   └── go.sum
├── app/                        # GoDeck Mobile Client (Flutter)
│   ├── lib/
│   │   ├── core/               # WebSocket Service, Haptic Feedback e Tema Neón Dark
│   │   ├── features/
│   │   │   ├── connection/     # Tela e status de conexão por IP/Porta
│   │   │   └── deck/           # Grid de botões, Trackpad e ações de automação
│   │   └── main.dart
│   ├── pubspec.yaml
│   └── analysis_options.yaml
├── Makefile                    # Comandos unificados para rodar app, server e testes
├── .gitignore
└── README.md
```

---

## ⚡ Guia Rápido de Instalação e Execução

### 1. Setup do Ambiente Local
Execute o script de inicialização para verificar e baixar as dependências do servidor e do aplicativo:

```bash
make setup
```

---

### 2. Executando o Servidor Host (Go Server)
Inicie o servidor no computador:

```bash
make run-server
```

Ao iniciar, o terminal exibirá os endereços IP da sua rede local para emparelhamento:
```text
==================================================
     🚀 GoDeck Host Server / Daemon v1.0         
==================================================
[Server] Server starting on 0.0.0.0:8080
[Server] Available local network IP addresses for mobile connection:
  👉 ws://192.168.1.100:8080/ws
```

---

### 3. Executando o Aplicativo Mobile (Flutter Client)
Em outro terminal (ou via Android Studio / VS Code), execute o app no emulador ou dispositivo físico:

```bash
make run-app
```

No aplicativo, clique no ícone de configurações no topo superior direito e insira o IP exibido no terminal do servidor (ex: `192.168.1.100`).

---

## 🧪 Testes e Compilação

- **Rodar todos os testes unitários (Go + Flutter)**:
  ```bash
  make test
  ```

- **Compilar o servidor para macOS, Linux e Windows**:
  ```bash
  make build-server
  ```
  Os binários gerados ficarão disponíveis na pasta `server/bin/`.

- **Gerar APK do aplicativo Android**:
  ```bash
  make build-app
  ```

---

## 📡 Protocolo WebSocket
As mensagens entre o aplicativo mobile e o servidor transitam em JSON sobre WebSocket com suporte a RTT ping/pong para monitorar a latência em tempo real. Consulte a documentação completa em [`docs/protocol-spec.md`](docs/protocol-spec.md).

---

## 🛠️ Tecnologias Utilizadas
- **Flutter** (Dart): UI reativa com feedback haptico, modo Trackpad multitouch e tema dark neón.
- **Go (Golang)**: Daemon concorrente com Gorilla WebSocket para processamento de baixa latência e emulação nativa de comandos no sistema operacional.
