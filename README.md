# Gateway - Nginx Reverse Proxy Centralizado

Gateway centralizado para rotear múltiplos serviços Docker através de um único ponto de entrada.

## Arquitetura

```
                    ┌─────────────────────────────────────┐
                    │            GATEWAY                   │
    Internet ──────▶│  Nginx (:80/:443)                   │
                    │                                      │
                    │  /api/*   → btc-api:8000            │
                    │  /        → btc-web:3000            │
                    │  /mcp/*   → btc-mcp:8001            │
                    │  /voice/* → voice-orchestrator:8000 │
                    └────────────────┬────────────────────┘
                                     │
                          shared-services network
                                     │
        ┌────────────────────────────┼────────────────────────────┐
        │                            │                            │
        ▼                            ▼                            ▼
┌───────────────┐          ┌───────────────┐          ┌───────────────┐
│ beyond-the-   │          │    voice-     │          │    outro      │
│ club          │          │ orchestrator  │          │   projeto     │
│               │          │               │          │               │
│ btc-api       │          │ orchestrator  │          │ service-name  │
│ btc-web       │          │ redis         │          │               │
│ btc-mcp       │          │               │          │               │
└───────────────┘          └───────────────┘          └───────────────┘
```

## Setup Inicial

```bash
# 1. Clonar repositório no servidor
git clone [repo-url] gateway
cd gateway

# 2. Rodar setup (cria rede compartilhada)
chmod +x scripts/*.sh
./scripts/setup.sh

# 3. Copiar certificados SSL
cp /path/to/fullchain.pem nginx/ssl/
cp /path/to/privkey.pem nginx/ssl/

# 4. Iniciar gateway
docker-compose up -d
```

## Ordem de Deploy

1. Criar rede: `docker network create shared-services`
2. Subir serviços backend (beyond-the-club, voice-orchestrator, etc.)
3. Subir gateway

## Adicionando Novo Serviço

### Opção 1: Script automático

```bash
./scripts/add-service.sh meu-servico 8080 /meu-path
```

### Opção 2: Manual

1. Adicionar upstream em `nginx/conf.d/upstreams.conf`:
```nginx
upstream meu-servico {
    server meu-servico:8080;
    keepalive 32;
}
```

2. Criar `nginx/conf.d/locations/meu-servico.conf`:
```nginx
location /meu-path/ {
    rewrite ^/meu-path/(.*)$ /$1 break;
    proxy_pass http://meu-servico;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

3. Atualizar docker-compose do serviço:
```yaml
services:
  meu-servico:
    container_name: meu-servico  # Deve corresponder ao upstream
    networks:
      - internal-network
      - shared-services

networks:
  internal-network:
    driver: bridge
  shared-services:
    external: true
```

4. Recarregar nginx:
```bash
./scripts/reload-nginx.sh
```

## Comandos Úteis

```bash
# Ver logs
docker logs gateway-nginx -f

# Testar configuração
docker exec gateway-nginx nginx -t

# Reload sem downtime
./scripts/reload-nginx.sh

# Ver rotas ativas
docker exec gateway-nginx cat /etc/nginx/conf.d/upstreams.conf
```

## Estrutura de Arquivos

```
gateway/
├── docker-compose.yml
├── nginx/
│   ├── nginx.conf              # Config principal
│   ├── conf.d/
│   │   ├── upstreams.conf      # Definição dos backends
│   │   └── locations/
│   │       ├── beyond.conf     # Rotas BTC
│   │       └── voice.conf      # Rotas Voice
│   └── ssl/
│       ├── fullchain.pem       # Certificado SSL
│       └── privkey.pem         # Chave privada
├── logs/                       # Logs do nginx
├── scripts/
│   ├── setup.sh               # Setup inicial
│   ├── reload-nginx.sh        # Reload configuração
│   └── add-service.sh         # Adicionar novo serviço
└── README.md
```

## Troubleshooting

### Erro "Network shared-services not found"
```bash
docker network create shared-services
```

### Erro "502 Bad Gateway"
- Verificar se o serviço está rodando
- Verificar se o container_name corresponde ao upstream
- Verificar se o serviço está na rede shared-services

### Verificar conectividade
```bash
# Do container nginx, tentar alcançar serviço
docker exec gateway-nginx wget -qO- http://btc-api:8000/api/v1/system/status
```
