-- =============================================================================
-- Tenant CCS — Planos comerciais iniciais
--
-- [09/05/2026 - Alexandre Carvalho] Valores PROVISORIOS — ajustar antes de
-- ir para producao. O ENTERPRISE fica com preco zero porque e sob consulta
-- (preenchido manualmente por cliente).
--
-- Idempotente: usa ON CONFLICT (codigo) DO UPDATE.
-- =============================================================================

SET search_path TO frota_tenant, public;

INSERT INTO plano (codigo, nome, preco_mensal, limite_veiculos, limite_usuarios, limite_filiais, descricao, ativo)
VALUES
    ('STARTER',
     'Starter',
     290.00,
     15,
     3,
     1,
     'Para frotas pequenas (ate 15 veiculos, 1 filial). Inclui modulos de cadastro, abastecimento, manutencao corretiva e checklist. Sem app mobile.',
     TRUE),

    ('BUSINESS',
     'Business',
     690.00,
     60,
     10,
     3,
     'Para frotas medias (ate 60 veiculos, 3 filiais). Tudo do Starter + plano de manutencao preventiva, controle de pneus, app mobile Android, relatorios gerenciais.',
     TRUE),

    ('ENTERPRISE',
     'Enterprise',
     0.00,
     NULL,
     NULL,
     NULL,
     'Frotas grandes/multi-filial. Limites ilimitados. Preco sob consulta — preencher manualmente no campo preco_mensal apos negociacao comercial. Inclui SLA dedicado e gerente de conta.',
     TRUE)

ON CONFLICT (codigo) DO UPDATE
SET nome           = EXCLUDED.nome,
    preco_mensal   = EXCLUDED.preco_mensal,
    limite_veiculos= EXCLUDED.limite_veiculos,
    limite_usuarios= EXCLUDED.limite_usuarios,
    limite_filiais = EXCLUDED.limite_filiais,
    descricao      = EXCLUDED.descricao,
    ativo          = EXCLUDED.ativo;
