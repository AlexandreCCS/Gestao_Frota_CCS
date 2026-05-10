# Pesquisa de campo — NR Group (Fleet)

Mapeamento da app NR Group (`fleet.nrgroup.app`) usada pela Quality, para inspirar features e definir o MVP do **Gestão de Frota CCS**.

## Pasta `screenshots/`

Imagens **não vão para o git** (`.gitignore` filtra). São ativos sensíveis (sessão Quality logada). Mantenha localmente em:

```
C:\Claudete\Gestao_Frota_CCS\docs\pesquisa-NR\screenshots\
```

## Checklist de captura

Cada subpasta corresponde a um módulo. Salve com os nomes sugeridos. Pode ir em ondas — comece pelo essencial (01, 03, 04).

| Pasta | O que printar | Nomes sugeridos |
|---|---|---|
| `00-login-dashboard/` | login + dashboard inicial + menu lateral | `01-login.png`, `02-dashboard.png`, `03-menu-lateral.png` |
| `01-veiculos/` | lista + ficha (todas as abas) + cadastro novo | `01-lista.png`, `02-ficha-aba1.png`, `03-novo.png` |
| `02-motoristas/` | lista + ficha + CNH/vencimentos | `01-lista.png`, `02-ficha.png`, `03-cnh.png` |
| `03-abastecimento/` | lista + lançamento + relatório KM/L + gráficos | `01-lista.png`, `02-novo.png`, `03-relatorio-kml.png` |
| `04-manutencao-os/` | lista de OS + abertura + plano preventivo + execução | `01-lista-os.png`, `02-nova-os.png`, `03-plano-preventivo.png`, `04-baixa.png` |
| `05-pneus/` | mapa de pneus + vida útil + rodízio | `01-mapa.png`, `02-vida.png`, `03-rodizio.png` |
| `06-checklist/` | templates + execução + histórico + foto | `01-templates.png`, `02-execucao.png`, `03-historico.png` |
| `07-viagens/` | lista + cadastro + acerto motorista | `01-lista.png`, `02-cadastro.png`, `03-acerto.png` |
| `08-documentos/` | vencimentos CRLV/IPVA/seguro + alertas | `01-vencimentos.png`, `02-alertas.png` |
| `09-financeiro/` | tela financeiro + contas integradas | `01-financeiro.png`, `02-contas.png` |
| `10-suprimentos/` | lista + compra | `01-lista.png`, `02-compra.png` |
| `11-relatorios-bi/` | painéis + relatórios + IA | `01-painel.png`, `02-rel-custo-km.png`, `03-ia.png` |
| `12-torre-controle/` | dashboard + cargas + alertas + cerca + telemetria | `01-dashboard.png`, `02-cargas.png`, `03-alertas.png`, `04-cerca.png`, `05-telemetria.png` |
| `13-app-android/` | todas as telas do app do motorista | `01-login.png`, `02-home.png`, `03-abastec.png`, `04-checklist.png`, `05-foto.png`, `06-gps.png` |
| `14-config-admin/` | postos, fornecedores, fabricantes, modelos, usuários | `01-postos.png`, `02-fabricantes.png`, `03-modelos.png`, `04-usuarios.png` |

## Notas livres

Use o arquivo [notas.md](notas.md) para registrar:

- O que achou bom (manter no nosso produto)
- O que achou ruim/lento/confuso (não copiar)
- O que cliente reclama / não entende
- Features que parecem inúteis (cortar do MVP)
- Features que faltam (oportunidade do nosso produto)

## Análise pós-captura

Quando os screenshots estiverem disponíveis, será gerado um arquivo **`analise.md`** mapeando:

1. Cada tela → quais campos / botões / fluxos
2. Cada campo → equivalente no nosso `CCS_TB_FROT_*`
3. Lacunas (features NR que não cobrimos no MVP — vão pro backlog)
4. Vantagens (features Mega que NR não tem — argumento de venda)
