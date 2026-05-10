-- =============================================================================
-- Tenant CCS — Planos de manutencao preventiva (modelos de referencia)
--
-- [09/05/2026 - Alexandre Carvalho] 3 planos iniciais cobrindo veiculo leve
-- gasolina, caminhao diesel e empilhadeira. Periodicidades sao MEDIAS DE
-- MERCADO — cada cliente ajusta segundo manual do fabricante e regime
-- de uso real ao importar para sua base.
--
-- Idempotente: TRUNCATE + INSERT.
-- =============================================================================

SET search_path TO frota_tenant, public;

BEGIN;

TRUNCATE TABLE catalogo_plano_manut_item
            RESTART IDENTITY CASCADE;
TRUNCATE TABLE catalogo_plano_manut
            RESTART IDENTITY CASCADE;

-- =============================================================================
-- Plano 1: Veiculo leve gasolina (carro / van administrativo)
-- =============================================================================

INSERT INTO catalogo_plano_manut
    (codigo, nome, modelo_referencia, segmento, descricao)
VALUES
    ('VEICULO_LEVE_GASOLINA',
     'Veiculo Leve Gasolina — manutencao padrao',
     'Carro / van administrativa',
     'GERAL',
     'Plano padrao para carros e vans flex/gasolina de uso administrativo. Cliente ajusta periodicidades conforme manual de cada modelo (Onix, Saveiro, Strada, Sprinter, etc.).');

INSERT INTO catalogo_plano_manut_item
    (plano_manut_id, ordem, servico, periodo_km, periodo_dias, periodo_horas, observacao)
SELECT p.plano_manut_id, x.ordem, x.servico, x.periodo_km, x.periodo_dias, x.periodo_horas, x.obs
  FROM catalogo_plano_manut p,
       (VALUES
            (1,  'Troca de oleo do motor + filtro',                10000,  365,  NULL,  'Oleo sintetico — pode estender ate 15.000km'),
            (2,  'Troca de filtro de ar',                          20000,  730,  NULL,  NULL),
            (3,  'Troca de filtro de combustivel',                 40000, 1095,  NULL,  NULL),
            (4,  'Troca de filtro de cabine',                      20000,  365,  NULL,  NULL),
            (5,  'Troca de velas de ignicao',                      40000, 1095,  NULL,  NULL),
            (6,  'Verificacao da correia dentada/poly-V',          50000, 1825,  NULL,  'Trocar conforme inspecao'),
            (7,  'Alinhamento e balanceamento',                    10000,  365,  NULL,  NULL),
            (8,  'Rodizio de pneus',                               10000,  365,  NULL,  NULL),
            (9,  'Verificacao do sistema de freio (pastilhas, fluido)', 20000, 365, NULL, NULL),
            (10, 'Higienizacao do ar condicionado',                40000,  730,  NULL,  NULL)
        ) AS x(ordem, servico, periodo_km, periodo_dias, periodo_horas, obs)
 WHERE p.codigo = 'VEICULO_LEVE_GASOLINA';


-- =============================================================================
-- Plano 2: Caminhao diesel (entrega, basculante, betoneira)
-- =============================================================================

INSERT INTO catalogo_plano_manut
    (codigo, nome, modelo_referencia, segmento, descricao)
VALUES
    ('CAMINHAO_DIESEL',
     'Caminhao Diesel — manutencao padrao',
     'Caminhao Mercedes-Benz / Volvo / Scania',
     'CONSTRUTORA',
     'Plano padrao para caminhoes leves, medios e pesados a diesel. Inclui ARLA-32 quando aplicavel. Cliente ajusta conforme manual do fabricante e regime severo (basculante, betoneira) reduz prazos em ~30%.');

INSERT INTO catalogo_plano_manut_item
    (plano_manut_id, ordem, servico, periodo_km, periodo_dias, periodo_horas, observacao)
SELECT p.plano_manut_id, x.ordem, x.servico, x.periodo_km, x.periodo_dias, x.periodo_horas, x.obs
  FROM catalogo_plano_manut p,
       (VALUES
            (1,  'Troca de oleo do motor + filtro',                30000,  180,  NULL,  'Em regime severo (basculante/betoneira) reduzir para 20000km'),
            (2,  'Troca de filtro de combustivel + separador agua',30000,  180,  NULL,  NULL),
            (3,  'Troca de filtro de ar',                          60000,  365,  NULL,  NULL),
            (4,  'Troca do filtro de ARLA-32 (se aplicavel)',      80000,  730,  NULL,  'Apenas Euro 5/6 com SCR'),
            (5,  'Verificacao do oleo da transmissao',             60000,  365,  NULL,  NULL),
            (6,  'Verificacao do oleo do diferencial',             60000,  365,  NULL,  NULL),
            (7,  'Verificacao das pastilhas/lonas de freio',       30000,  180,  NULL,  NULL),
            (8,  'Verificacao do sistema pneumatico (compressor, secador)', 60000, 365, NULL, NULL),
            (9,  'Lubrificacao do chassi (graxeiras)',             10000,   30,  NULL,  'Crucial em basculante e betoneira'),
            (10, 'Alinhamento de eixos (truck/cavalo)',            60000,  365,  NULL,  NULL),
            (11, 'Rodizio de pneus (5+1)',                         30000,  180,  NULL,  NULL),
            (12, 'Verificacao da suspensao (feixe de mola, balanca)',60000, 365,  NULL,  NULL),
            (13, 'Inspecao do tacografo (selo do INMETRO)',         NULL,  730,  NULL,  'Obrigatoria a cada 2 anos'),
            (14, 'Vistoria estrutural caçamba/carroceria',         60000,  180,  NULL,  'Para basculante e graneleiro')
        ) AS x(ordem, servico, periodo_km, periodo_dias, periodo_horas, obs)
 WHERE p.codigo = 'CAMINHAO_DIESEL';


-- =============================================================================
-- Plano 3: Empilhadeira (eletrica/GLP/diesel)
-- =============================================================================

INSERT INTO catalogo_plano_manut
    (codigo, nome, modelo_referencia, segmento, descricao)
VALUES
    ('EMPILHADEIRA_GLP_ELETRICA',
     'Empilhadeira (GLP / Eletrica) — manutencao padrao',
     'Empilhadeira Hyster / Toyota / Linde / Still',
     'INDUSTRIA',
     'Plano por horimetro (uso mais relevante que km). Comum a empilhadeiras GLP, eletricas e diesel. Cliente ajusta conforme manual e tipo (contrabalançada, retratil, paleteira).');

INSERT INTO catalogo_plano_manut_item
    (plano_manut_id, ordem, servico, periodo_km, periodo_dias, periodo_horas, observacao)
SELECT p.plano_manut_id, x.ordem, x.servico, x.periodo_km, x.periodo_dias, x.periodo_horas, x.obs
  FROM catalogo_plano_manut p,
       (VALUES
            (1,  'Troca de oleo do motor + filtro (combustao)',     NULL,  180,   500,  'Apenas para GLP/diesel'),
            (2,  'Troca do oleo hidraulico + filtro',               NULL,  365,  2000,  'Critico para vida util do mastro'),
            (3,  'Verificacao do oleo da transmissao',              NULL,  365,  1000,  NULL),
            (4,  'Verificacao da bateria (eletrica) — densidade e nivel',NULL, 30, 250, 'Apenas eletricas — manutencao quinzenal'),
            (5,  'Limpeza dos terminais e plugue da bateria',       NULL,   90,   500,  'Apenas eletricas'),
            (6,  'Lubrificacao das correntes do mastro',            NULL,   30,   250,  NULL),
            (7,  'Inspecao das correntes do mastro (alongamento)',  NULL,  180,  1000,  'Trocar se passar de 2% de alongamento'),
            (8,  'Inspecao dos garfos (trinca, desgaste no calcanhar)',NULL, 180, 1000, NULL),
            (9,  'Inspecao dos pneus / rodas',                      NULL,   90,   500,  NULL),
            (10, 'Verificacao do freio de servico e estacionamento',NULL,   90,   500,  NULL),
            (11, 'Verificacao do sistema hidraulico (mangueiras, vazamentos)',NULL,90,500, NULL),
            (12, 'Inspecao do cinto de seguranca / OPS (operator presence sensor)',NULL,90,500, NULL),
            (13, 'Calibracao do sensor de carga (se aplicavel)',    NULL,  365,  2000,  NULL)
        ) AS x(ordem, servico, periodo_km, periodo_dias, periodo_horas, obs)
 WHERE p.codigo = 'EMPILHADEIRA_GLP_ELETRICA';


COMMIT;
