# Seeds do Tenant Central CCS

Conjunto de dados iniciais para popular o schema `frota_tenant` (Postgres) após criar o schema com [`../schema.sql`](../schema.sql).

> Aplicar **na ordem numérica**. Cada arquivo é **idempotente** (pode rodar múltiplas vezes).

## Arquivos

| Ordem | Arquivo | O que insere | Estratégia |
|---|---|---|---|
| 1 | [`01_planos.sql`](01_planos.sql) | 3 planos comerciais: `STARTER`, `BUSINESS`, `ENTERPRISE` | `ON CONFLICT DO UPDATE` |
| 2 | [`02_checklist_templates.sql`](02_checklist_templates.sql) | 4 templates pré-prontos: pré-viagem veículo leve / caminhão / empilhadeira + inspeção mensal | `TRUNCATE + INSERT` |
| 3 | [`03_planos_manutencao.sql`](03_planos_manutencao.sql) | 3 planos preventivos: veículo leve gasolina / caminhão diesel / empilhadeira | `TRUNCATE + INSERT` |

## Aplicação

### Local (psql)

```powershell
cd C:\Claudete\Gestao_Frota_CCS

# Schema primeiro (se ainda não rodado)
psql -h 127.0.0.1 -p 5432 -U postgres -d frota_tenant_dev -f tenant/schema.sql

# Seeds, em ordem
psql -h 127.0.0.1 -p 5432 -U postgres -d frota_tenant_dev -f tenant/seeds/01_planos.sql
psql -h 127.0.0.1 -p 5432 -U postgres -d frota_tenant_dev -f tenant/seeds/02_checklist_templates.sql
psql -h 127.0.0.1 -p 5432 -U postgres -d frota_tenant_dev -f tenant/seeds/03_planos_manutencao.sql
```

### Container Docker (na VPS srv-ccs depois do deploy)

```bash
ssh ccs@76.13.171.138

# Schema (se necessário)
docker exec -i frota-tenant-db psql -U frota -d frota_tenant < tenant/schema.sql

# Seeds
for f in tenant/seeds/*.sql; do
  echo "=== $f ==="
  docker exec -i frota-tenant-db psql -U frota -d frota_tenant < "$f"
done
```

## Avisos importantes

### Valores comerciais são PROVISÓRIOS

Os preços e limites em `01_planos.sql` (`STARTER R$ 290`, `BUSINESS R$ 690`, `ENTERPRISE sob consulta`) são **placeholders para desenvolvimento**. Antes de qualquer venda, ajustar conforme a estratégia comercial real.

### Templates são REFERÊNCIA — cliente customiza na sua base

Os 4 templates de checklist e os 3 planos de manutenção daqui não são "verdade absoluta". Quando um cliente é provisionado, o `frota-api` copia o template selecionado **uma vez** para a base do cliente (`MEGA.CCS_TB_FROT_CHK_TEMPLATE`) e a partir daí ele edita à vontade — adiciona itens, remove, muda perguntas. As mudanças do cliente **não voltam** para o tenant central.

Atualizações nos templates daqui afetam apenas **futuras importações** (clientes novos ou que solicitarem reset).

### Periodicidades de manutenção são MÉDIAS DE MERCADO

`Veiculo leve gasolina` / `caminhão diesel` / `empilhadeira` têm periodicidades **médias** baseadas em manuais comuns. Cliente deve ajustar segundo:

- Manual específico de cada modelo (Onix ≠ Saveiro ≠ Strada)
- Regime de uso (basculante e betoneira reduzem prazos em ~30%)
- Condições do ambiente (poeira, calor, salinidade)

## Próximos seeds (PRs futuros)

- `04_categorias_veiculo.sql` — taxonomia de tipos de veículo (CARRO, VAN, CAMINHAO_LEVE, CAMINHAO_PESADO, EMPILHADEIRA, ESCAVADEIRA, ...)
- `05_tipos_despesa.sql` — taxonomia de despesas (PEDAGIO, REFEICAO, HOSPEDAGEM, MULTA, ...)
- `06_usuario_master_admin.sql` — cria usuário admin inicial CCS (via env, com hash bcrypt)
