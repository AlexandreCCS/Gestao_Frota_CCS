# Arquitetura — Gestão de Frota CCS

> Documento vivo. Última atualização: **09/05/2026** (Alexandre Carvalho).

## 1. Princípios

1. **Multi-tenant pelo banco do cliente.** Cada cliente CCS roda no seu próprio Oracle Mega. O produto não tem "banco operacional central".
2. **Tenant central só faz licenciamento.** Postgres pequeno na VPS Hostinger CCS. Sem dado operacional do cliente lá.
3. **Lógica de negócio em PL/SQL.** Padrão CCS — toda regra fica em `CCS_PCK_FROT_*` no schema MEGA do cliente. Backend Node é fino: auth, bridge SOAP, uploads.
4. **Não tocar nas tabelas `FRO_*` nativas do Mega.** Schema próprio `CCS_TB_FROT_*` enxuto, voltado a indústria e construtora. Reaproveitar `FRO_FABRICANTE`/`FRO_MODELO`/`FRO_CATEGORIA` apenas como lookup (FK opcional).
5. **Reaproveitar o que o Mega já tem por integração natural.** `GLO_AGENTES`, `ORG_FILIAL`, `CUS_*`, `FIN_VW_CONTASPAGAR`, `EST_MOVIMENTO` — não duplicar cadastro.

## 2. Diagrama lógico

```
            ┌────────────────────────────────────────────────┐
            │  TENANT CENTRAL CCS — Postgres na VPS srv-ccs  │
            │  - clientes (OCPDB, plano, limites)            │
            │  - usuarios_master (gerentes/suporte CCS)      │
            │  - feature_flags por cliente                   │
            │  - catalogo_checklist_template                 │
            │  - catalogo_plano_manutencao_template          │
            │  - telemetria_uso (anonimizada/agregada)       │
            │  - audit_log (login, ativação, mudança plano)  │
            └──────┬─────────────────────────────────────────┘
                   │ (HTTP REST)
                   ▼
┌──────────────────────────────────────────────────────────────────┐
│  frota.ccstecno.com.br                                           │
│   ├─ frota-api  (Node Fastify, :3030)                            │
│   │    ├─ /auth                  (JWT, integra usuario Mega)     │
│   │    ├─ /tenant/license/check  (cache 5min do tenant central)  │
│   │    ├─ /api/*                 (proxy SOAP → CCS_PCK_FROT_*)   │
│   │    └─ /upload                (foto checklist, cupom, KM)     │
│   └─ frota-web  (Vite React, :3031, nginx)                       │
│   └─ frota-mobile (Capacitor APK)                                │
└──────┬───────────────────────────────────────────────────────────┘
       │ (SOAP HTTPS para apiquality1.ccstecno.com.br)
       ▼
┌──────────────────────────────────────────────────────────────────┐
│  ORACLE MEGA DO CLIENTE  (ex.: Quality OCPDB493)                 │
│   Tabelas operacionais (CCS_TB_FROT_*)                           │
│   Pacotes (CCS_PCK_FROT_*)                                       │
│   Views (CCS_VW_FROT_*)                                          │
│   Reaproveita do Mega: GLO_AGENTES, ORG_*, CUS_*, FIN_*, EST_*   │
└──────────────────────────────────────────────────────────────────┘
```

## 3. Stack

| Camada | Tecnologia | Onde roda |
|---|---|---|
| Web frontend | React 19 + Vite | container `frota-web` na VPS |
| Mobile Android | Capacitor (mesma base React) | APK próprio, `mobile/android/` |
| API | Node 22 + Fastify 5 | container `frota-api` na VPS |
| Reverse-proxy/HTTPS | Caddy 2.11 | host VPS |
| Tenant DB | Postgres 16 | container `frota-tenant-db` na VPS (ou reuso) |
| DB operacional | Oracle 19c (Mega do cliente) | infra do cliente, acesso via SOAP |
| Bridge ao Oracle | webservice `apiquality1` (SOAP) | infra CCS |

## 4. Padrões CCS aplicados

- **SOAP direto via `https` Node**, nunca MCP. Template canônico em `C:\Claudete\Instruções\Conexoes.md`.
- **SQL e PL/SQL em UPPERCASE** (keywords + identificadores). Strings literais mantêm case.
- **Joins legacy**: vírgula no `FROM` + `WHERE` + `(+)`. Proibido ANSI.
- **Comentário de alteração**: `[DD/MM/YYYY - Alexandre Carvalho]` no bloco alterado.
- **Pós-DDL**: `DBMS_UTILITY.COMPILE_SCHEMA('MEGA', FALSE)` + lista de objetos `INVALID` antes/depois.
- **Auditoria**: para cada `CCS_TB_FROT_X`, par `CCS_TB_FROT_X_AUD` (snapshot OLD/NEW) com trigger AFTER I/U/D.
- **Refcursor obrigatório** em procedures chamadas via `GetProcedureObj` (do app Comercial, se viermos a usar).
- **Customização Mega XT**: se precisar de form custom, registrar em `GLO_FORMULA` (ver `Customizacao_Mega.md`).

## 5. O que NÃO usar

- ❌ Tabelas `FRO_*` nativas Mega para escrita (são módulo Mega XT, com regras proprietárias)
- ❌ Joins ANSI (`JOIN`, `LEFT JOIN`, `RIGHT JOIN`, `OUTER JOIN`, `CROSS JOIN`)
- ❌ MCP (apesar do nome `mcp-oracle-soap` ser um diretório local — só registry)
- ❌ Senior, RM, ADP — sem integração com nenhum sistema externo de RH/folha no MVP
- ❌ Mobile iOS no MVP (Android only — decisão registrada em decisões técnicas)

## 6. Decisões pendentes

- Política de autenticação: usar o usuário Mega do cliente (tabela própria `MEGA.USU_*`) ou criar usuário paralelo Frota? — afeta UX e onboarding.
- Padrão de upload de foto: armazenar na VPS (S3-like local) ou em BLOB no Oracle (com chunking de 32KB conforme `Conexoes.md` §1)?
- Granularidade do plano comercial: por veículo ativo? por usuário ativo? por filial?
- Integração com cerca eletrônica/rastreador: definir interface mínima (lista curta de marcas suportadas no MVP).

## 7. Referências internas

- `C:\Claudete\Instruções\Regras_Gerais.md` — regras transversais CCS
- `C:\Claudete\Instruções\Conexoes.md` — credenciais SOAP por OCPDB
- `C:\Claudete\Instruções\Padroes_Tecnicos_MEGA_CCS.md` — pegadinhas SOAP/Oracle
- `C:\Claudete\Instruções\Deploy_VPS_Tar_Scp_Docker.md` — pipeline de deploy
- `C:\Claudete\Instruções\Bot_Whats_CCS_Status.md` — estilo de produto SaaS CCS atual
- `C:\Claudete\Instruções\Customizacao_Mega.md` — forms custom Mega XT (caso necessário)
