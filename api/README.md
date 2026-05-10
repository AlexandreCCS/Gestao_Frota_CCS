# frota-api

Backend HTTP do **Gestão de Frota CCS**. Fina por design:

- **Não** carrega lógica de negócio — essa fica em PL/SQL no Oracle Mega do cliente.
- **Carrega**: autenticação, bridge SOAP para `apiquality1`, leitura/gravação no tenant Postgres central, uploads, validações de input.

## Stack

| Item | Versão |
|---|---|
| Node | 22 (alpine no container) |
| Fastify | 5.x |
| Postgres client | `pg` 8.x |
| JWT | `@fastify/jwt` |
| CORS | `@fastify/cors` |

## Endpoints (estado atual)

| Método | Rota | Status | Descrição |
|---|---|---|---|
| `GET` | `/health` | ✅ | Liveness (sem dependências) |
| `GET` | `/health/ready` | ✅ | Readiness (pinga Postgres tenant) |
| `POST` | `/auth/login` | 🟡 stub 501 | Estrutura definida, lógica no próximo PR |
| `GET` | `/auth/me` | 🟡 stub 501 | Estrutura definida |
| `POST` | `/auth/logout` | ✅ no-op 204 | Cliente descarta token |

## Estrutura de pastas

```
api/
├── Dockerfile
├── .dockerignore
├── .env.example
├── package.json
├── README.md
└── src/
    ├── server.js          ← entry point (Fastify + registros)
    ├── config.js          ← carrega .env sem dependência
    ├── lib/
    │   ├── soap.js        ← bridge para apiquality1 (template canônico CCS)
    │   └── tenant.js      ← pool Postgres do tenant central
    └── routes/
        ├── health.js      ← /health e /health/ready
        └── auth.js        ← /auth/* (stub)
```

## Rodar localmente

Requer **Node 22+**. Postgres tenant é opcional — `/health/ready` vai retornar `degraded` se ele estiver offline, mas o resto da API funciona.

```powershell
cd api
copy .env.example .env
# editar .env conforme necessário (em dev pode deixar quase tudo como está)

npm install
npm run dev
```

Depois, num outro terminal:

```powershell
curl http://localhost:3030/health
curl http://localhost:3030/health/ready
curl -X POST http://localhost:3030/auth/login -H "Content-Type: application/json" -d "{}"
```

`npm run dev` usa `node --watch` (Node 22+) — recarrega automaticamente em mudanças de arquivo.

## Build do container

```powershell
docker build -t frota-api:dev api/
docker run -d --name frota-api-dev `
  --env-file api/.env `
  -p 3030:3030 `
  frota-api:dev

# logs
docker logs -f frota-api-dev
```

## Padrão CCS aplicado

- **SOAP direto via `https` Node** ([src/lib/soap.js](src/lib/soap.js)) — template canônico de [Conexoes.md §1](../docs/arquitetura.md). Detecta erro tanto em `<MENSAGEM>` quanto em `<ERRO>`.
- **Sem `dotenv`** — config próprio em [src/config.js](src/config.js), padrão dos crons CCS.
- **Comentários com `[DD/MM/YYYY - Alexandre Carvalho]`** em cada arquivo no cabeçalho.

## Próximos PRs

| PR | Conteúdo |
|---|---|
| `feature/api-auth-real` | `/auth/login` real: valida no Oracle do cliente via SOAP, emite JWT, persiste sessão no tenant |
| `feature/api-veiculo-crud` | `/api/veiculos` GET/POST/PUT/DELETE → `CCS_PCK_FROT_VEICULO` |
| `feature/api-upload-foto` | `/upload` para fotos de checklist/cupom (storage local na VPS) |
| `feature/api-tenant-license` | `/tenant/license/check` com cache 5min |
