# Tenant Central CCS

Banco **Postgres** que hospeda **apenas** licenciamento, catálogo de templates pré-prontos, telemetria agregada e log de auditoria administrativa.

> **Não armazena dado operacional do cliente.** Veículos, motoristas, abastecimentos, OS, pneus, viagens etc. ficam 100% no Oracle Mega de cada cliente, no schema MEGA com prefixo `CCS_TB_FROT_*`.

## Conteúdo

| Arquivo | Descrição |
|---|---|
| [schema.sql](schema.sql) | DDL completo do schema `frota_tenant` (criação inicial) |
| `migrations/` | Migrations sequenciais a partir do segundo deploy (ainda vazio) |

## Schema `frota_tenant`

```
plano                            ← planos comerciais (BASIC, PRO, ENT, ...)
cliente                          ← cada cliente CCS Mega (1 OCPDB = 1 linha)
feature_flag                     ← override de feature por cliente
usuario_master                   ← equipe CCS (admin/suporte/comercial)
catalogo_checklist_template      ← templates pré-prontos de checklist
catalogo_checklist_item          ← itens de cada template
catalogo_plano_manut             ← planos de manutenção preventiva por modelo
catalogo_plano_manut_item        ← itens (serviço + periodicidade)
telemetria_evento                ← eventos agregados (login, ações, plataforma)
audit_log                        ← operações administrativas (criar/suspender)
trg_set_atualizado_em()          ← função genérica para trigger BEFORE UPDATE
```

## Como rodar localmente (dev)

Postgres 16 ou superior:

```powershell
# A partir da raiz do repo
psql "postgresql://postgres:postgres@localhost:5432/frota_tenant_dev" -f tenant/schema.sql
```

Ou via container Docker (sem instalar Postgres):

```powershell
docker run -d --name frota-tenant-dev `
  -e POSTGRES_PASSWORD=dev `
  -p 5434:5432 `
  postgres:16-alpine

# aguarda subir e aplica schema
docker cp tenant/schema.sql frota-tenant-dev:/tmp/schema.sql
docker exec -e PGPASSWORD=dev frota-tenant-dev psql -U postgres -c "CREATE DATABASE frota_tenant_dev;"
docker exec -e PGPASSWORD=dev frota-tenant-dev psql -U postgres -d frota_tenant_dev -f /tmp/schema.sql
```

## Deploy na VPS CCS

A VPS Hostinger CCS (`srv-ccs`) já tem múltiplos containers Postgres (gf-redis, blumi-postgres, bot-whats-db). Vamos criar um novo dedicado: **`frota-tenant-db`**, exposto apenas no loopback `127.0.0.1:5435`.

Compose stub (vai para `vps/docker-compose.yml` quando montarmos a stack completa):

```yaml
services:
  frota-tenant-db:
    image: postgres:16-alpine
    container_name: frota-tenant-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: frota_tenant
      POSTGRES_USER: ${TENANT_DB_USER}
      POSTGRES_PASSWORD: ${TENANT_DB_PASSWORD}
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - ./db/data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${TENANT_DB_USER} -d frota_tenant"]
      interval: 10s
      timeout: 5s
      retries: 5
    ports:
      - "127.0.0.1:5435:5432"
```

## Convenções de nomenclatura

- Tabelas e colunas em **snake_case minúsculo** (padrão Postgres) — diferente do Oracle do cliente que usa UPPERCASE com prefixos `CCS_TB_*`.
- Datas/timestamps com timezone (`TIMESTAMPTZ`).
- IDs auto-incremento via `SERIAL` / `BIGSERIAL`.
- `criado_em` e `atualizado_em` em todas as tabelas-mestre, com trigger automática.
- Constraints nomeadas (`<tabela>_<coluna>_chk`, `<tabela>_<colunas>_uk`).

## Próximos passos

- [ ] Adicionar `migrations/` com Knex/Flyway/sql-migrate quando passarmos do schema inicial
- [ ] Seed de planos comerciais e templates de catálogo (`tenant/seeds/` em PR separado)
- [ ] Backup automático do volume Postgres (cron na VPS)
- [ ] Restringir acesso ao banco apenas via app `frota-api` (firewall interno do Docker)
