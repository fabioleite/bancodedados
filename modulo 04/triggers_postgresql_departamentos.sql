-- ============================================================
-- Script: Triggers PostgreSQL - Schema departamentos (Banco Aulas)
-- Objetivo: instalar todos os exemplos de trigger da apostila
-- Execucao: psql ou pgAdmin, conectado ao banco Aulas
-- ============================================================

BEGIN;

-- 0) Garantir que o schema existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.schemata
        WHERE schema_name = 'departamentos'
    ) THEN
        RAISE EXCEPTION 'Schema departamentos nao encontrado.';
    END IF;
END;
$$;

-- 1) Tabelas auxiliares
CREATE TABLE IF NOT EXISTS departamentos.auditoria_divisao (
    id_auditoria BIGSERIAL PRIMARY KEY,
    id_divisao INT NOT NULL,
    chefe_antigo INT NULL,
    chefe_novo INT NULL,
    alterado_em TIMESTAMP NOT NULL DEFAULT NOW(),
    alterado_por TEXT NOT NULL DEFAULT CURRENT_USER
);

CREATE TABLE IF NOT EXISTS departamentos.folha_resumo (
    id_empregado INT PRIMARY KEY,
    total_vencimentos NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_descontos NUMERIC(12,2) NOT NULL DEFAULT 0,
    salario_liquido NUMERIC(12,2) NOT NULL DEFAULT 0,
    atualizado_em TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_folha_resumo_empregado
        FOREIGN KEY (id_empregado)
        REFERENCES departamentos.empregado(id_empregado)
);

-- 2) Exemplo 1 - Validar CPF numerico no cadastro de empregado
CREATE OR REPLACE FUNCTION departamentos.fn_trg_empregado_valida_cpf()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.cpf IS NULL OR NEW.cpf !~ '^[0-9]{11}$' THEN
        RAISE EXCEPTION 'CPF invalido. Informe exatamente 11 digitos numericos.';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_empregado_valida_cpf ON departamentos.empregado;

CREATE TRIGGER trg_empregado_valida_cpf
BEFORE INSERT OR UPDATE OF cpf
ON departamentos.empregado
FOR EACH ROW
EXECUTE FUNCTION departamentos.fn_trg_empregado_valida_cpf();

-- 3) Exemplo 2 - Garantir periodo de gestao valido no departamento
CREATE OR REPLACE FUNCTION departamentos.fn_trg_departamento_periodo_gestao()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.data_inicio_gestao IS NOT NULL
       AND NEW.data_fim_gestao IS NOT NULL
       AND NEW.data_fim_gestao < NEW.data_inicio_gestao THEN
        RAISE EXCEPTION 'Data fim de gestao nao pode ser menor que data inicio.';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_departamento_periodo_gestao ON departamentos.departamento;

CREATE TRIGGER trg_departamento_periodo_gestao
BEFORE INSERT OR UPDATE OF data_inicio_gestao, data_fim_gestao
ON departamentos.departamento
FOR EACH ROW
EXECUTE FUNCTION departamentos.fn_trg_departamento_periodo_gestao();

-- 4) Exemplo 3 - Auditar troca de chefe de divisao
CREATE OR REPLACE FUNCTION departamentos.fn_trg_divisao_audita_chefe()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NEW.id_chefe IS DISTINCT FROM OLD.id_chefe) THEN
        INSERT INTO departamentos.auditoria_divisao (
            id_divisao,
            chefe_antigo,
            chefe_novo,
            alterado_em,
            alterado_por
        )
        VALUES (
            NEW.id_divisao,
            CASE WHEN TG_OP = 'INSERT' THEN NULL ELSE OLD.id_chefe END,
            NEW.id_chefe,
            NOW(),
            CURRENT_USER
        );
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_divisao_audita_chefe ON departamentos.divisao;

CREATE TRIGGER trg_divisao_audita_chefe
AFTER INSERT OR UPDATE OF id_chefe
ON departamentos.divisao
FOR EACH ROW
EXECUTE FUNCTION departamentos.fn_trg_divisao_audita_chefe();

-- 5) Exemplo 4 - Impedir chefe de divisao fora do mesmo departamento
CREATE OR REPLACE FUNCTION departamentos.fn_trg_divisao_valida_chefe_departamento()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_departamento_chefe INT;
BEGIN
    IF NEW.id_chefe IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT d.id_departamento
      INTO v_departamento_chefe
      FROM departamentos.empregado e
      JOIN departamentos.divisao d
        ON d.id_divisao = e.id_divisao
     WHERE e.id_empregado = NEW.id_chefe;

    IF v_departamento_chefe IS NULL THEN
        RAISE EXCEPTION 'Chefe informado nao existe ou nao esta lotado em divisao valida.';
    END IF;

    IF v_departamento_chefe <> NEW.id_departamento THEN
        RAISE EXCEPTION 'Chefe da divisao deve pertencer ao mesmo departamento da divisao.';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_divisao_valida_chefe_departamento ON departamentos.divisao;

CREATE TRIGGER trg_divisao_valida_chefe_departamento
BEFORE INSERT OR UPDATE OF id_chefe, id_departamento
ON departamentos.divisao
FOR EACH ROW
EXECUTE FUNCTION departamentos.fn_trg_divisao_valida_chefe_departamento();

-- 6) Exemplo 5 - Recalcular folha resumo apos mudancas de vencimentos/descontos
CREATE OR REPLACE FUNCTION departamentos.fn_recalcula_folha_resumo(p_id_empregado INT)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_venc NUMERIC(12,2);
    v_total_desc NUMERIC(12,2);
BEGIN
    SELECT COALESCE(SUM(v.valor), 0)
      INTO v_total_venc
      FROM departamentos.empregado_vencimento ev
      JOIN departamentos.vencimento v
        ON v.id_vencimento = ev.id_vencimento
     WHERE ev.id_empregado = p_id_empregado;

    SELECT COALESCE(SUM(d.valor), 0)
      INTO v_total_desc
      FROM departamentos.empregado_desconto ed
      JOIN departamentos.desconto d
        ON d.id_desconto = ed.id_desconto
     WHERE ed.id_empregado = p_id_empregado;

    INSERT INTO departamentos.folha_resumo (
        id_empregado,
        total_vencimentos,
        total_descontos,
        salario_liquido,
        atualizado_em
    )
    VALUES (
        p_id_empregado,
        v_total_venc,
        v_total_desc,
        v_total_venc - v_total_desc,
        NOW()
    )
    ON CONFLICT (id_empregado)
    DO UPDATE
       SET total_vencimentos = EXCLUDED.total_vencimentos,
           total_descontos = EXCLUDED.total_descontos,
           salario_liquido = EXCLUDED.salario_liquido,
           atualizado_em = NOW();
END;
$$;

CREATE OR REPLACE FUNCTION departamentos.fn_trg_empregado_vencimento_recalcula()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM departamentos.fn_recalcula_folha_resumo(COALESCE(NEW.id_empregado, OLD.id_empregado));
    RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_empregado_vencimento_recalcula ON departamentos.empregado_vencimento;

CREATE TRIGGER trg_empregado_vencimento_recalcula
AFTER INSERT OR UPDATE OR DELETE
ON departamentos.empregado_vencimento
FOR EACH ROW
EXECUTE FUNCTION departamentos.fn_trg_empregado_vencimento_recalcula();

CREATE OR REPLACE FUNCTION departamentos.fn_trg_empregado_desconto_recalcula()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM departamentos.fn_recalcula_folha_resumo(COALESCE(NEW.id_empregado, OLD.id_empregado));
    RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_empregado_desconto_recalcula ON departamentos.empregado_desconto;

CREATE TRIGGER trg_empregado_desconto_recalcula
AFTER INSERT OR UPDATE OR DELETE
ON departamentos.empregado_desconto
FOR EACH ROW
EXECUTE FUNCTION departamentos.fn_trg_empregado_desconto_recalcula();

COMMIT;

-- 7) Consultas rapidas para conferir instalacao
-- SELECT trigger_name, event_object_table, action_timing, event_manipulation
-- FROM information_schema.triggers
-- WHERE trigger_schema = 'departamentos'
-- ORDER BY event_object_table, trigger_name;
