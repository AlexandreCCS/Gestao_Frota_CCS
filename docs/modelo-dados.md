# Modelo de Dados — Gestão de Frota CCS

> Esqueleto inicial. Detalhamento de campos virá depois da pesquisa NR (screenshots) e do refinamento de escopo do MVP.
>
> Última atualização: **09/05/2026** (Alexandre Carvalho).

## Convenções

- Schema: **MEGA** (no Oracle do cliente).
- Prefixo: **`CCS_TB_FROT_*`** (tabela), **`CCS_VW_FROT_*`** (view), **`CCS_PCK_FROT_*`** (pacote), **`CCS_T_FROT_*`** (trigger), **`CCS_JOB_FROT_*`** (job DBMS Scheduler).
- PK numérica via sequence: **`CCS_SEQ_FROT_<ENTIDADE>`** (NUMBER 12).
- Toda tabela operacional com par **`_AUD`** (auditoria — snapshot OLD/NEW, trigger AFTER I/U/D, padrão CCS).
- FKs Mega usadas como referência:
  - **`GLO_AGENTES.AGN_IN_CODIGO`** — motorista (TAU=F funcionário), posto (TAU=F fornecedor combustível), oficina externa (TAU=F fornecedor manut).
  - **`ORG_FILIAL.FIL_IN_CODIGO`** + **`ORG_EMPRESA.ORG_IN_CODIGO`** — filial dona do veículo.
  - **`CUS_CENTROCUSTO.CCF_IN_CODIGO`** — centro de custo para rateio.
  - **`EST_PRODUTO.PRO_IN_CODIGO`** — peça consumida em OS dá baixa em `EST_MOVIMENTO`.
  - **`FRO_FABRICANTE.FAB_IN_CODIGO`** / **`FRO_MODELO.MOD_IN_CODIGO`** / **`FRO_CATEGORIA.CAT_IN_CODIGO`** — *somente leitura*, para reuso de lookups Mega quando houver.

## Entidades

### Núcleo

| Tabela | Função | Notas |
|---|---|---|
| `CCS_TB_FROT_VEICULO` | cadastro de veículo/equipamento | placa, chassi, RENAVAM, FK fabricante/modelo/categoria, FIL, CCusto, KM atual, status (ativo/manutenção/inativo) |
| `CCS_TB_FROT_MOTORISTA` | dados do motorista | FK GLO_AGENTES (funcionário), CNH (categoria + validade), tipo sanguíneo, telefone, foto |
| `CCS_TB_FROT_VINCULO_MOT_VEIC` | quem dirige o quê | data início/fim, vínculo principal vs secundário |

### Operação

| Tabela | Função | Notas |
|---|---|---|
| `CCS_TB_FROT_ABASTECIMENTO` | lançamento de abastecimento | data/hora, KM, qtd L, valor, FK posto AGN, NF, foto cupom, dentro/fora bomba interna |
| `CCS_TB_FROT_LEITURA_KM` | check independente do hodômetro | data, KM, fonte (motorista/portaria/manut) |
| `CCS_TB_FROT_VIAGEM` | viagem (rota completa) | header com origem/destino, KM ini/fim, despesas, acerto motorista |
| `CCS_TB_FROT_VIAGEM_DESPESA` | despesas avulsas da viagem | tipo (pedágio, refeição, etc.), valor, foto comprovante |

### Manutenção

| Tabela | Função | Notas |
|---|---|---|
| `CCS_TB_FROT_OS` | ordem de serviço | preventiva / corretiva / socorro; oficina interna ou externa (FK GLO_AGENTES) |
| `CCS_TB_FROT_OS_ITEM` | linhas da OS | peça (FK EST_PRODUTO) ou serviço; valor unit, qtd; baixa estoque se interna |
| `CCS_TB_FROT_PLANO_MANUT` | plano preventivo | por modelo de veículo: a cada X km / Y dias / Z horas |
| `CCS_TB_FROT_PLANO_ITEM` | itens do plano | óleo, filtro, freio, etc., com periodicidade própria |

### Pneus / Componentes

| Tabela | Função | Notas |
|---|---|---|
| `CCS_TB_FROT_PNEU` | pneu como ativo individual | série, marca, medida, vida útil estimada, KM acumulado |
| `CCS_TB_FROT_PNEU_POSICAO` | mapeamento atual no veículo | eixo + lado + posição; histórico via _AUD |

### Documentos

| Tabela | Função | Notas |
|---|---|---|
| `CCS_TB_FROT_DOC` | CRLV, IPVA, seguro, ANTT, multa | tipo, número, vigência, valor, anexo (BLOB ou path) |

### Checklist

| Tabela | Função | Notas |
|---|---|---|
| `CCS_TB_FROT_CHK_TEMPLATE` | template de checklist | nome, tipo (pré-viagem, pós-viagem, mensal, troca de motorista) |
| `CCS_TB_FROT_CHK_TEMPLATE_ITEM` | itens do template | pergunta, tipo resposta (OK/NOK, número, foto), obrigatório? |
| `CCS_TB_FROT_CHK_EXEC` | execução do checklist | header com veículo, motorista, KM, data |
| `CCS_TB_FROT_CHK_EXEC_RESP` | resposta por item | resposta, observação, FK foto |
| `CCS_TB_FROT_CHK_FOTO` | fotos vinculadas | BLOB ou path (decisão pendente — ver arquitetura.md §6) |

### Tenant central (Postgres na VPS, NÃO no Oracle do cliente)

| Tabela | Função |
|---|---|
| `cliente` | cadastro CCS de cada cliente Mega (OCPDB, plano, status) |
| `plano` | tabela de planos comerciais |
| `feature_flag` | quais features cada cliente tem ativas |
| `usuario_master` | gestores e suporte CCS (cross-cliente) |
| `catalogo_checklist_template` | templates pré-prontos que o cliente importa no onboarding |
| `catalogo_plano_manutencao` | planos preventivos por modelo (banco de boas práticas) |
| `telemetria_evento` | uso agregado/anonimizado para análise interna CCS |
| `audit_log` | login, mudança de plano, ativação/desativação |

## Auditoria

Para cada `CCS_TB_FROT_X` operacional, criar `CCS_TB_FROT_X_AUD` com:

- mesma estrutura da tabela origem
- colunas extras: `AUD_IN_CODIGO` (PK), `AUD_CH_OPERACAO` (`I`/`U`/`D`), `AUD_DT_DATA`, `AUD_ST_USUARIO`, `AUD_ST_HOST`
- trigger compound `AFTER INSERT OR UPDATE OR DELETE` que insere snapshot completo (OLD para D/U, NEW para I/U)
- detalhes em `C:\Claudete\Instruções\Auditoria_Mega.md`

## Próximos passos de modelagem

1. Após pesquisa NR (screenshots) — refinar campos de cada tabela.
2. Decidir FK opcional para `FRO_FABRICANTE`/`FRO_MODELO`/`FRO_CATEGORIA` (reuso) ou criar tabelas próprias.
3. Definir política de fotos (BLOB Oracle vs storage VPS).
4. Definir granularidade de tenant: cobrar por veículo ativo vs por usuário vs por filial.
