-- =============================================================================
-- Tenant Central CCS — Gestao de Frota
-- Postgres 16+
--
-- [09/05/2026 - Alexandre Carvalho] Schema inicial
--
-- Escopo deste banco:
--   1) Licenciamento (cliente -> plano, limites, status)
--   2) Catalogo de templates pre-prontos (checklist e plano de manutencao)
--   3) Telemetria de uso agregada (anonimizada)
--   4) Auditoria de operacoes administrativas
--
-- O QUE NAO VAI AQUI:
--   - Dados operacionais do cliente (veiculos, motoristas, abastecimentos,
--     OS, pneus, viagens) — esses ficam 100% no Oracle Mega de cada cliente,
--     no schema MEGA com prefixo CCS_TB_FROT_*.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS frota_tenant;
SET search_path TO frota_tenant, public;

-- =============================================================================
-- 1. LICENCIAMENTO
-- =============================================================================

-- Plano comercial
CREATE TABLE plano (
    plano_id          SERIAL        PRIMARY KEY,
    codigo            VARCHAR(20)   NOT NULL UNIQUE,
    nome              VARCHAR(80)   NOT NULL,
    preco_mensal      NUMERIC(10,2) NOT NULL,
    limite_veiculos   INTEGER,
    limite_usuarios   INTEGER,
    limite_filiais    INTEGER,
    descricao         TEXT,
    ativo             BOOLEAN       NOT NULL DEFAULT TRUE,
    criado_em         TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    atualizado_em     TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN plano.limite_veiculos IS 'NULL = ilimitado';
COMMENT ON COLUMN plano.limite_usuarios IS 'NULL = ilimitado';
COMMENT ON COLUMN plano.limite_filiais  IS 'NULL = ilimitado';


-- Cliente CCS (cada um corresponde a um Mega OCPDB)
CREATE TABLE cliente (
    cliente_id        SERIAL        PRIMARY KEY,
    ocpdb             VARCHAR(20)   NOT NULL UNIQUE,
    razao_social      VARCHAR(150)  NOT NULL,
    fantasia          VARCHAR(80),
    cnpj              CHAR(14)      NOT NULL UNIQUE,
    email_contato     VARCHAR(120),
    telefone          VARCHAR(20),
    oracle_user       VARCHAR(40)   NOT NULL,
    plano_id          INTEGER       NOT NULL REFERENCES plano(plano_id) ON DELETE RESTRICT,
    data_inicio       DATE          NOT NULL,
    data_fim          DATE,
    status            VARCHAR(20)   NOT NULL DEFAULT 'ATIVO',
    observacao        TEXT,
    criado_em         TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    atualizado_em     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT cliente_status_chk
        CHECK (status IN ('ATIVO', 'SUSPENSO', 'CANCELADO', 'TRIAL'))
);

CREATE INDEX cliente_status_idx ON cliente(status);
CREATE INDEX cliente_plano_idx  ON cliente(plano_id);

COMMENT ON TABLE  cliente             IS 'Cada linha representa um cliente CCS Mega licenciado para o Gestao de Frota';
COMMENT ON COLUMN cliente.ocpdb       IS 'Codigo Mega do cliente (ex.: OCPDB493 para Quality)';
COMMENT ON COLUMN cliente.oracle_user IS 'Usuario do banco Mega (senha NAO fica aqui — vai em .env do api ou gestor de segredo)';
COMMENT ON COLUMN cliente.data_fim    IS 'NULL enquanto contrato vigente';


-- Override de feature por cliente (alem do plano)
CREATE TABLE feature_flag (
    cliente_id        INTEGER       NOT NULL REFERENCES cliente(cliente_id) ON DELETE CASCADE,
    feature           VARCHAR(60)   NOT NULL,
    ativo             BOOLEAN       NOT NULL DEFAULT TRUE,
    motivo            TEXT,
    criado_em         TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    PRIMARY KEY (cliente_id, feature)
);

COMMENT ON TABLE feature_flag IS 'Override de feature por cliente — sobrepoe o que o plano libera. Usado para liberar feature beta para um cliente especifico, ou bloquear feature em SLA.';


-- =============================================================================
-- 2. USUARIOS MASTER (suporte/comercial CCS, cross-cliente)
-- =============================================================================

CREATE TABLE usuario_master (
    usuario_id        SERIAL        PRIMARY KEY,
    email             VARCHAR(120)  NOT NULL UNIQUE,
    nome              VARCHAR(80)   NOT NULL,
    senha_hash        VARCHAR(120)  NOT NULL,
    perfil            VARCHAR(30)   NOT NULL,
    ativo             BOOLEAN       NOT NULL DEFAULT TRUE,
    ultimo_login      TIMESTAMPTZ,
    criado_em         TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    atualizado_em     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT usuario_master_perfil_chk
        CHECK (perfil IN ('ADMIN', 'SUPORTE', 'COMERCIAL'))
);

COMMENT ON TABLE  usuario_master         IS 'Equipe CCS — acesso ao painel administrativo cross-cliente. NAO sao usuarios finais (esses ficam no Mega do cliente).';
COMMENT ON COLUMN usuario_master.perfil  IS 'ADMIN: tudo. SUPORTE: leitura + abrir ticket. COMERCIAL: ver clientes/planos, sem dado operacional.';


-- =============================================================================
-- 3. CATALOGO DE TEMPLATES (importados pelo cliente no onboarding)
-- =============================================================================

-- Templates de checklist (pre-viagem, pos-viagem, mensal, etc.)
CREATE TABLE catalogo_checklist_template (
    template_id       SERIAL        PRIMARY KEY,
    codigo            VARCHAR(40)   NOT NULL UNIQUE,
    nome              VARCHAR(120)  NOT NULL,
    tipo              VARCHAR(30)   NOT NULL,
    segmento          VARCHAR(40),
    descricao         TEXT,
    ativo             BOOLEAN       NOT NULL DEFAULT TRUE,
    criado_em         TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    atualizado_em     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_template_tipo_chk
        CHECK (tipo IN ('PRE_VIAGEM', 'POS_VIAGEM', 'MENSAL', 'TROCA_MOTORISTA', 'INSPECAO_OFICINA'))
);

CREATE TABLE catalogo_checklist_item (
    item_id           SERIAL        PRIMARY KEY,
    template_id       INTEGER       NOT NULL REFERENCES catalogo_checklist_template(template_id) ON DELETE CASCADE,
    ordem             INTEGER       NOT NULL,
    pergunta          TEXT          NOT NULL,
    tipo_resposta     VARCHAR(20)   NOT NULL,
    obrigatorio       BOOLEAN       NOT NULL DEFAULT TRUE,
    observacao        TEXT,
    CONSTRAINT chk_item_tipo_resposta_chk
        CHECK (tipo_resposta IN ('BOOLEAN', 'NUMERO', 'TEXTO', 'FOTO', 'SELECAO')),
    CONSTRAINT chk_item_template_ordem_uk UNIQUE (template_id, ordem)
);

COMMENT ON TABLE catalogo_checklist_template IS 'Modelos pre-prontos que o cliente importa no onboarding e edita a vontade na sua base.';


-- Plano de manutencao preventiva por modelo (banco de boas praticas)
CREATE TABLE catalogo_plano_manut (
    plano_manut_id    SERIAL        PRIMARY KEY,
    codigo            VARCHAR(40)   NOT NULL UNIQUE,
    nome              VARCHAR(120)  NOT NULL,
    modelo_referencia VARCHAR(80),
    segmento          VARCHAR(40),
    descricao         TEXT,
    ativo             BOOLEAN       NOT NULL DEFAULT TRUE,
    criado_em         TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    atualizado_em     TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE catalogo_plano_manut_item (
    item_id           SERIAL        PRIMARY KEY,
    plano_manut_id    INTEGER       NOT NULL REFERENCES catalogo_plano_manut(plano_manut_id) ON DELETE CASCADE,
    ordem             INTEGER       NOT NULL,
    servico           VARCHAR(120)  NOT NULL,
    periodo_km        INTEGER,
    periodo_dias      INTEGER,
    periodo_horas     INTEGER,
    observacao        TEXT,
    CONSTRAINT plano_manut_item_ordem_uk UNIQUE (plano_manut_id, ordem),
    CONSTRAINT plano_manut_item_periodicidade_chk
        CHECK (periodo_km IS NOT NULL OR periodo_dias IS NOT NULL OR periodo_horas IS NOT NULL)
);

COMMENT ON COLUMN catalogo_plano_manut_item.periodo_km    IS 'A cada X km (NULL = nao usa)';
COMMENT ON COLUMN catalogo_plano_manut_item.periodo_dias  IS 'A cada Y dias (NULL = nao usa)';
COMMENT ON COLUMN catalogo_plano_manut_item.periodo_horas IS 'A cada Z horas de horimetro (NULL = nao usa)';


-- =============================================================================
-- 4. TELEMETRIA DE USO (agregada, anonimizada)
-- =============================================================================

CREATE TABLE telemetria_evento (
    evento_id         BIGSERIAL     PRIMARY KEY,
    cliente_id        INTEGER       REFERENCES cliente(cliente_id) ON DELETE SET NULL,
    evento            VARCHAR(60)   NOT NULL,
    qtde              INTEGER       NOT NULL DEFAULT 1,
    data_referencia   DATE          NOT NULL DEFAULT CURRENT_DATE,
    metadata          JSONB,
    criado_em         TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX telemetria_evento_data_idx     ON telemetria_evento(data_referencia DESC);
CREATE INDEX telemetria_evento_cli_evt_idx  ON telemetria_evento(cliente_id, evento);
CREATE INDEX telemetria_evento_metadata_idx ON telemetria_evento USING GIN (metadata);

COMMENT ON TABLE  telemetria_evento          IS 'Eventos agregados por cliente/dia/tipo. NAO contem dado pessoal nem operacional sensivel — apenas contadores e flags de feature.';
COMMENT ON COLUMN telemetria_evento.evento   IS 'Ex.: login, abast_lancado, os_aberta, checklist_executado, mobile_open';
COMMENT ON COLUMN telemetria_evento.metadata IS 'Atributos opcionais — ex.: {"plataforma":"android","versao":"1.2.0"}';


-- =============================================================================
-- 5. AUDIT LOG (operacoes administrativas no tenant central)
-- =============================================================================

CREATE TABLE audit_log (
    log_id            BIGSERIAL     PRIMARY KEY,
    ts                TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    usuario_master_id INTEGER       REFERENCES usuario_master(usuario_id) ON DELETE SET NULL,
    cliente_id        INTEGER       REFERENCES cliente(cliente_id) ON DELETE SET NULL,
    acao              VARCHAR(60)   NOT NULL,
    detalhe           JSONB,
    ip                INET,
    user_agent        TEXT
);

CREATE INDEX audit_log_ts_idx     ON audit_log(ts DESC);
CREATE INDEX audit_log_cli_idx    ON audit_log(cliente_id);
CREATE INDEX audit_log_acao_idx   ON audit_log(acao);

COMMENT ON COLUMN audit_log.acao IS 'Ex.: cliente.criar, cliente.suspender, plano.alterar, feature_flag.ativar, usuario_master.login';


-- =============================================================================
-- 6. TRIGGERS DE atualizado_em
-- =============================================================================

CREATE OR REPLACE FUNCTION trg_set_atualizado_em() RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER plano_set_atualizado
    BEFORE UPDATE ON plano
    FOR EACH ROW EXECUTE FUNCTION trg_set_atualizado_em();

CREATE TRIGGER cliente_set_atualizado
    BEFORE UPDATE ON cliente
    FOR EACH ROW EXECUTE FUNCTION trg_set_atualizado_em();

CREATE TRIGGER usuario_master_set_atualizado
    BEFORE UPDATE ON usuario_master
    FOR EACH ROW EXECUTE FUNCTION trg_set_atualizado_em();

CREATE TRIGGER catalogo_checklist_template_set_atualizado
    BEFORE UPDATE ON catalogo_checklist_template
    FOR EACH ROW EXECUTE FUNCTION trg_set_atualizado_em();

CREATE TRIGGER catalogo_plano_manut_set_atualizado
    BEFORE UPDATE ON catalogo_plano_manut
    FOR EACH ROW EXECUTE FUNCTION trg_set_atualizado_em();
