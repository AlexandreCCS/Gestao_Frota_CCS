# Gestão de Frota CCS

Add-on do **Mega ERP** para gestão de frota própria, com foco em **indústria e construtora**.

> Status: **planejamento** (09/05/2026). Sem código de aplicação ainda — apenas arquitetura e modelagem inicial.

## Posicionamento

| Concorrente | Público | Ticket |
|---|---|---|
| NR Group (`nrgroup.app`) | transportadoras | a partir de R$ 600/mês |
| Senior módulo Frotas | grandes operações | licença "cara" (Mega integra) |
| **Gestão de Frota CCS** | **indústria + construtora** com frota própria, já clientes do Mega | acessível, integrado nativamente |

A premissa é simples: o cliente Mega já tem `GLO_AGENTES`, `ORG_FILIAL`, `CUS_*`, `FIN_VW_CONTASPAGAR`, `EST_MOVIMENTO`. Em vez de pagar SaaS externo que **não conversa** com o ERP, oferecer uma camada moderna (web + Android) que **vive dentro do Oracle do cliente** e nasce integrada ao financeiro, estoque e centro de custo.

## Arquitetura em uma frase

Multi-tenant: **tenant central** (Postgres na VPS CCS, só licença/plano/catálogo/telemetria) + **dado operacional 100% no Oracle do cliente** (schema MEGA, prefixo `CCS_TB_FROT_*`).

Detalhes em [docs/arquitetura.md](docs/arquitetura.md).

## Stack

- **Backend** — Node Fastify (containerizado, igual `gestor-financeiro-ccs`)
- **Web** — React + Vite, deploy via Caddy reverse-proxy em `frota.ccstecno.com.br`
- **Mobile** — Android via Capacitor (decisão registrada em [docs/decisoes-tecnicas.md](docs/decisoes-tecnicas.md))
- **Banco operacional** — Oracle do cliente Mega (SOAP via `apiquality1.ccstecno.com.br`)
- **Banco tenant** — Postgres na VPS Hostinger CCS
- **Lógica de negócio** — em PL/SQL no Mega do cliente (padrão CCS), pacotes `CCS_PCK_FROT_*`

## Estrutura do repo

```
.
├── docs/             documentação viva (arquitetura, modelo de dados, pesquisa NR, decisões)
├── sql/              DDL/DML organizado por categoria (schema, views, packages, triggers, jobs, seed)
├── api/              backend Node Fastify
├── web/              frontend React + Vite
├── mobile/           wrapper Android Capacitor
├── tenant/           schema Postgres do tenant central CCS
├── vps/              deploy (docker-compose, Caddy snippet, scripts)
└── .env.example
```

## Cliente piloto

**Quality Varejo** (OCPDB493) — atualmente paga R$ 875/mês ao NR Group (RMS Consultoria, AGN 22801) sem usar nenhum módulo nativo de frota do Mega. Baseline para medir antes/depois.

## Roadmap

Definido conforme avança a pesquisa de campo (screenshots da app NR + entrevistas). Será mantido em [docs/roadmap.md](docs/roadmap.md) quando houver conteúdo para listar.

## Convenções

Seguir as regras transversais CCS — ver `C:\Claudete\Instruções\Regras_Gerais.md` (não versionado neste repo).

Resumo:

- **SQL/PL-SQL em UPPERCASE** (keywords e identificadores)
- **Joins legacy** — vírgula + WHERE + `(+)`. Proibido ANSI JOIN
- Toda alteração comentada com **`[DD/MM/YYYY - Alexandre Carvalho]`**
- Pós-DDL: `DBMS_UTILITY.COMPILE_SCHEMA('MEGA', FALSE)` + reportar INVALID
- Padrão de tabelas: `CCS_TB_FROT_*` (operacional) e `CCS_TB_FROT_*_AUD` (auditoria)
- Padrão de pacotes: `CCS_PCK_FROT_*`
- Padrão de views: `CCS_VW_FROT_*`
