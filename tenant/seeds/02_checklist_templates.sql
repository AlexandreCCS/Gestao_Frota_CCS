-- =============================================================================
-- Tenant CCS — Templates de checklist pre-prontos
--
-- [09/05/2026 - Alexandre Carvalho] 4 templates iniciais cobrindo
-- pre-viagem (veiculo leve, caminhao, empilhadeira) e inspecao mensal geral.
--
-- Cliente importa esses templates no onboarding e edita a vontade na
-- propria base Oracle (CCS_TB_FROT_CHK_TEMPLATE). Aqui no tenant central
-- ficam apenas como modelos de referencia.
--
-- Idempotente: TRUNCATE + INSERT (catalogo nao tem dado historico do cliente).
-- =============================================================================

SET search_path TO frota_tenant, public;

BEGIN;

TRUNCATE TABLE catalogo_checklist_item
            RESTART IDENTITY CASCADE;
TRUNCATE TABLE catalogo_checklist_template
            RESTART IDENTITY CASCADE;

-- =============================================================================
-- Template 1: Pre-viagem veiculo leve (carro/van administrativo)
-- =============================================================================

INSERT INTO catalogo_checklist_template
    (codigo, nome, tipo, segmento, descricao)
VALUES
    ('PRE_VIAGEM_VEICULO_LEVE',
     'Pre-viagem — Veiculo Leve',
     'PRE_VIAGEM',
     'GERAL',
     'Inspecao rapida antes de sair com carro/van administrativo (gerente, vendedor, supervisor). 8 itens, ~2 minutos.');

INSERT INTO catalogo_checklist_item
    (template_id, ordem, pergunta, tipo_resposta, obrigatorio, observacao)
SELECT t.template_id, x.ordem, x.pergunta, x.tipo_resposta, x.obrigatorio, x.obs
  FROM catalogo_checklist_template t,
       (VALUES
            (1,  'Hodometro (km atual)',                                  'NUMERO',   TRUE,  NULL),
            (2,  'Foto do hodometro',                                     'FOTO',     TRUE,  'Tirar foto do painel mostrando o KM'),
            (3,  'Combustivel acima de 1/4 do tanque?',                  'BOOLEAN',  TRUE,  NULL),
            (4,  'Pneus em bom estado (sem ranhuras profundas, calibrados)?','BOOLEAN', TRUE, NULL),
            (5,  'Lampadas (faroletes, lanternas, freio) funcionando?',   'BOOLEAN',  TRUE,  NULL),
            (6,  'Veiculo limpo por dentro e por fora?',                  'BOOLEAN',  FALSE, NULL),
            (7,  'Documentos (CRLV, seguro) na guantera?',                'BOOLEAN',  TRUE,  NULL),
            (8,  'Observacoes / pontos de atencao',                       'TEXTO',    FALSE, 'Riscos, lampadas a trocar, ruidos')
        ) AS x(ordem, pergunta, tipo_resposta, obrigatorio, obs)
 WHERE t.codigo = 'PRE_VIAGEM_VEICULO_LEVE';


-- =============================================================================
-- Template 2: Pre-viagem caminhao (entrega, basculante)
-- =============================================================================

INSERT INTO catalogo_checklist_template
    (codigo, nome, tipo, segmento, descricao)
VALUES
    ('PRE_VIAGEM_CAMINHAO',
     'Pre-viagem — Caminhao',
     'PRE_VIAGEM',
     'CONSTRUTORA',
     'Inspecao completa antes da rota — caminhao de entrega, basculante, betoneira. 15 itens, ~5 minutos.');

INSERT INTO catalogo_checklist_item
    (template_id, ordem, pergunta, tipo_resposta, obrigatorio, observacao)
SELECT t.template_id, x.ordem, x.pergunta, x.tipo_resposta, x.obrigatorio, x.obs
  FROM catalogo_checklist_template t,
       (VALUES
            (1,  'Hodometro (km atual)',                                  'NUMERO',   TRUE,  NULL),
            (2,  'Foto do hodometro',                                     'FOTO',     TRUE,  NULL),
            (3,  'Combustivel acima de 1/2 tanque?',                      'BOOLEAN',  TRUE,  NULL),
            (4,  'Oleo do motor (verificar vareta) OK?',                  'BOOLEAN',  TRUE,  NULL),
            (5,  'Agua do radiador OK?',                                  'BOOLEAN',  TRUE,  NULL),
            (6,  'Fluido de freio OK?',                                   'BOOLEAN',  TRUE,  NULL),
            (7,  'Pneus em bom estado e calibrados (5 pontos)?',          'BOOLEAN',  TRUE,  'Verificar incluindo o estepe'),
            (8,  'Lampadas externas (faroletes, sinaleiras, freio, re) funcionando?', 'BOOLEAN', TRUE, NULL),
            (9,  'Buzina e setas funcionando?',                           'BOOLEAN',  TRUE,  NULL),
            (10, 'Cinto de seguranca OK?',                                'BOOLEAN',  TRUE,  NULL),
            (11, 'Tacografo (se aplicavel) calibrado?',                   'BOOLEAN',  FALSE, NULL),
            (12, 'Carga amarrada/contida adequadamente?',                 'BOOLEAN',  TRUE,  'Para basculante: caçamba travada'),
            (13, 'Documentos (CRLV, ANTT, MDF-e) presentes?',             'BOOLEAN',  TRUE,  NULL),
            (14, 'Foto da carga / cacamba antes de sair',                 'FOTO',     FALSE, NULL),
            (15, 'Observacoes / pontos de atencao',                       'TEXTO',    FALSE, 'Vazamentos, ruidos, alertas no painel')
        ) AS x(ordem, pergunta, tipo_resposta, obrigatorio, obs)
 WHERE t.codigo = 'PRE_VIAGEM_CAMINHAO';


-- =============================================================================
-- Template 3: Pre-operacao empilhadeira (industria)
-- =============================================================================

INSERT INTO catalogo_checklist_template
    (codigo, nome, tipo, segmento, descricao)
VALUES
    ('PRE_OPERACAO_EMPILHADEIRA',
     'Pre-operacao — Empilhadeira',
     'PRE_VIAGEM',
     'INDUSTRIA',
     'Inspecao antes de iniciar turno com empilhadeira (eletrica, GLP ou diesel). NR-11 / OSHA-aligned. 12 itens, ~3 minutos.');

INSERT INTO catalogo_checklist_item
    (template_id, ordem, pergunta, tipo_resposta, obrigatorio, observacao)
SELECT t.template_id, x.ordem, x.pergunta, x.tipo_resposta, x.obrigatorio, x.obs
  FROM catalogo_checklist_template t,
       (VALUES
            (1,  'Horimetro (h atual)',                                   'NUMERO',   TRUE,  NULL),
            (2,  'Foto do horimetro',                                     'FOTO',     TRUE,  NULL),
            (3,  'Tipo de combustivel/energia',                           'SELECAO',  TRUE,  'Eletrica / GLP / Diesel'),
            (4,  'Carga da bateria / nivel de combustivel adequado?',     'BOOLEAN',  TRUE,  NULL),
            (5,  'Garfos e mastro sem trincas / deformacoes visiveis?',   'BOOLEAN',  TRUE,  NULL),
            (6,  'Correntes do mastro tensionadas e lubrificadas?',       'BOOLEAN',  TRUE,  NULL),
            (7,  'Pneus / rodas em bom estado?',                          'BOOLEAN',  TRUE,  NULL),
            (8,  'Freio de servico e de estacionamento OK?',              'BOOLEAN',  TRUE,  NULL),
            (9,  'Buzina, alarme de re e luz de aviso (giroflex) OK?',    'BOOLEAN',  TRUE,  NULL),
            (10, 'Cinto de seguranca / barra de protecao OK?',            'BOOLEAN',  TRUE,  NULL),
            (11, 'Vazamentos sob a empilhadeira?',                        'BOOLEAN',  TRUE,  'Verificar oleo hidraulico, agua'),
            (12, 'Observacoes / pontos de atencao',                       'TEXTO',    FALSE, NULL)
        ) AS x(ordem, pergunta, tipo_resposta, obrigatorio, obs)
 WHERE t.codigo = 'PRE_OPERACAO_EMPILHADEIRA';


-- =============================================================================
-- Template 4: Inspecao mensal geral (qualquer veiculo)
-- =============================================================================

INSERT INTO catalogo_checklist_template
    (codigo, nome, tipo, segmento, descricao)
VALUES
    ('INSPECAO_MENSAL_GERAL',
     'Inspecao Mensal — Geral',
     'MENSAL',
     'GERAL',
     'Vistoria mensal mais aprofundada (todos os tipos). Executada pelo encarregado de frota ou mecanico. 18 itens, ~10 minutos.');

INSERT INTO catalogo_checklist_item
    (template_id, ordem, pergunta, tipo_resposta, obrigatorio, observacao)
SELECT t.template_id, x.ordem, x.pergunta, x.tipo_resposta, x.obrigatorio, x.obs
  FROM catalogo_checklist_template t,
       (VALUES
            (1,  'Hodometro / horimetro atual',                           'NUMERO',   TRUE,  NULL),
            (2,  'Foto do hodometro / horimetro',                         'FOTO',     TRUE,  NULL),
            (3,  'Foto frontal do veiculo',                               'FOTO',     TRUE,  NULL),
            (4,  'Foto traseira do veiculo',                              'FOTO',     TRUE,  NULL),
            (5,  'Foto lateral esquerda',                                 'FOTO',     TRUE,  NULL),
            (6,  'Foto lateral direita',                                  'FOTO',     TRUE,  NULL),
            (7,  'Carroceria sem amassados / arranhoes novos?',           'BOOLEAN',  TRUE,  NULL),
            (8,  'Vidros e espelhos integros?',                           'BOOLEAN',  TRUE,  NULL),
            (9,  'Bancos e cintos em bom estado?',                        'BOOLEAN',  TRUE,  NULL),
            (10, 'Pintura geral OK?',                                     'BOOLEAN',  FALSE, NULL),
            (11, 'Profundidade do sulco dos pneus (mm) — menor valor',    'NUMERO',   TRUE,  'Limite legal: 1.6mm'),
            (12, 'Bateria — terminais limpos e firmes?',                  'BOOLEAN',  TRUE,  NULL),
            (13, 'Filtros (ar, oleo, combustivel) dentro do prazo?',      'BOOLEAN',  TRUE,  NULL),
            (14, 'Correia dentada/poly-V sem desgaste excessivo?',        'BOOLEAN',  FALSE, NULL),
            (15, 'Suspensao sem ruidos anormais?',                        'BOOLEAN',  TRUE,  NULL),
            (16, 'Sistema eletrico — todas as luzes e alertas OK?',       'BOOLEAN',  TRUE,  NULL),
            (17, 'Documentos em dia (CRLV, IPVA, seguro)?',               'BOOLEAN',  TRUE,  NULL),
            (18, 'Observacoes gerais / pendencias para OS',               'TEXTO',    FALSE, NULL)
        ) AS x(ordem, pergunta, tipo_resposta, obrigatorio, obs)
 WHERE t.codigo = 'INSPECAO_MENSAL_GERAL';


COMMIT;
