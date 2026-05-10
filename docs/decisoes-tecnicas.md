# Decisões Técnicas

> Registra escolhas que moldam o produto. Cada decisão tem data, contexto e alternativas descartadas.

## D-001 — Cliente piloto: Quality (09/05/2026)

**Decisão:** o piloto será a **Quality Varejo (OCPDB493)**.

**Razão:** Alexandre tem acesso à app NR Group da Quality (login + screenshots) — permite mapear feature por feature e medir baseline (R$ 875/mês pagos hoje à RMS Consultoria, AGN 22801). SOAP `apiquality1` já está plenamente operacional.

**Alternativas descartadas:** Arouca (manufatura pesada — bom segundo cliente, mas sem acesso à app NR), Britos / KR / VentiSilva (sem urgência), Tutty (cliente novo, base não mapeada).

---

## D-002 — Mobile: Android only via Capacitor (09/05/2026)

**Decisão:** MVP terá app Android (sem iOS), construído com **Capacitor** (`@capacitor/core`).

**Razão:**
- Maioria dos motoristas no Brasil usa Android.
- Sem custo Apple Developer (US$ 99/ano), sem TestFlight, sem revisão Apple.
- Capacitor permite reuso de **90-95% do código React+Vite** do web — equipe enxuta, uma base de código.
- Plugins prontos para câmera, GPS background, notificação, biometria, file system.

**Alternativas descartadas:**
- **TWA (Trusted Web Activity)** — muito limitado em GPS background.
- **React Native** — UI nativa real, mas exige reescrita visual completa. Considerar futuro se performance virar gargalo.
- **Kotlin nativo** — zero reuso, custo desnecessário no MVP.
- **iOS** — fase 2, depois de validar produto e ROI.

---

## D-003 — Lógica de negócio: PL/SQL no Mega do cliente (09/05/2026)

**Decisão:** toda regra de negócio fica em **`CCS_PCK_FROT_*`** no schema MEGA do cliente. Backend Node é fino (auth + bridge SOAP + uploads).

**Razão:**
- Padrão CCS atual — toda lógica visível em `Consulta SQL CCS`, BI direto, auditoria via `CCS_TB_*_AUD`.
- Mega é fonte da verdade — sem duplicação de estado.
- Performance: aggregations enormes rodam dentro do Oracle (próximas aos dados).

**Trade-off aceito:**
- Iteração mais lenta que Node puro (deploy de package via SOAP, ciclo dev mais longo).
- Mais difícil "stub" para testes — depende do banco.

**Alternativa descartada:** "Backend Node faz lógica, Oracle só persiste" — perde aderência ao padrão CCS, dificulta uso de `Consulta SQL CCS`, e tira valor do que já temos pronto em PL/SQL.

---

## D-004 — Não usar `FRO_*` Mega como tabelas operacionais (09/05/2026)

**Decisão:** criar schema próprio **`CCS_TB_FROT_*`** enxuto, voltado a indústria/construtora. Não escrever nas tabelas `FRO_*` nativas Mega.

**Razão (investigação 09/05/2026):**
- 296 objetos `FRO_*` no schema Mega da Quality, todos VALID — mas todas as tabelas estão **vazias** (0 registros em `FRO_EQUIPAMENTO`, `FRO_ABASTECIMENTO`, `FRO_OS`, `FRO_DESPESAS`...).
- Nenhum cliente CCS usa o módulo `FRO_*` Mega de fato (confirmado pelo Alexandre).
- Schema `FRO_*` é overkill — projetado para mineração/agronegócio/transportadora (296 objetos com `FRO_PRODUCAOCTO`, `FRO_PROGROTARH`, `FRO_BOLETIM`, etc.).
- Manutenção Mega XT futura pode quebrar nossas customizações se mexermos nas tabelas oficiais.
- Triggers Mega proprietárias podem disparar comportamentos que não controlamos.

**O que reaproveitamos:**
- ✅ `GLO_AGENTES`, `ORG_*`, `CUS_*`, `FIN_VW_CONTASPAGAR`, `EST_MOVIMENTO`
- ✅ Lookups `FRO_FABRICANTE` / `FRO_MODELO` / `FRO_CATEGORIA` (somente leitura)
- ✅ Customizações CCS pré-existentes na Quality (`CCS_VW_VEICULOS`, `CCS_VW_MOTORISTA`, `CCS_VW_RELATORIO_ABASTECIMENTO`, `CCS_TB_ROTAVEICULO`, `CCS_TB_TIPOVEIC`) — analisar se há aproveitamento.

---

## D-005 — Tenant central com 3 escopos (09/05/2026)

**Decisão:** Postgres na VPS armazena três coisas e nada mais:

1. **Licenciamento** — clientes, planos, limites, feature flags.
2. **Catálogo de modelos pré-prontos** — templates de checklist, planos de manutenção. Cliente importa no onboarding e edita à vontade.
3. **Telemetria de uso agregada** — anonimizada, para entender quais features engajam.

**Não vai para o tenant central:**
- ❌ Dados operacionais do cliente (veículos, motoristas, abastecimentos) — ficam no Oracle dele.
- ❌ Marketplace de integrações (rastreador/posto) — fase futura, fora do MVP.

---

*Decisões futuras serão registradas como D-006, D-007, ...*
