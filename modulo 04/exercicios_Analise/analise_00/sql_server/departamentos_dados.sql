SET NOCOUNT ON;
GO

BEGIN TRY
    BEGIN TRAN;

    -- Departamento sem gerente inicialmente (evita dependencia ciclica na carga).
    SET IDENTITY_INSERT departamentos.departamento ON;

    INSERT INTO departamentos.departamento (
        id_departamento,
        nome,
        endereco_rua,
        endereco_numero,
        endereco_bairro,
        endereco_cidade,
        endereco_cep,
        endereco_uf,
        id_gerente,
        data_inicio_gestao,
        data_fim_gestao
    )
    VALUES
        (1, 'Engenharia', 'Av. das Industrias', '120', 'Bancarios', 'Cuite', '58040000', 'PB', NULL, '2022-02-15', NULL),
        (2, 'Calculo Estrutural e Concreto', 'Rua do Concreto', '300', 'Miramar', 'Cuite', '58041000', 'PB', NULL, '2021-01-01', NULL),
        (3, 'Recursos Humanos', 'Rua das Palmeiras', '50', 'Torre', 'Cuite', '58042000', 'PB', NULL, '2022-05-18', NULL);

    SET IDENTITY_INSERT departamentos.departamento OFF;

    SET IDENTITY_INSERT departamentos.divisao ON;

    INSERT INTO departamentos.divisao (
        id_divisao,
        nome,
        endereco_rua,
        endereco_numero,
        endereco_bairro,
        endereco_cidade,
        endereco_cep,
        endereco_uf,
        id_departamento,
        id_chefe
    )
    VALUES
        (1, 'Projetos', 'Av. das Industrias', '120', 'Bancarios', 'Cuite', '58040000', 'PB', 1, NULL),
        (2, 'Fiscalizacao', 'Av. das Industrias', '150', 'Bancarios', 'Cuite', '58040000', 'PB', 1, NULL),
        (3, 'Estruturas Metalicas', 'Rua do Concreto', '300', 'Miramar', 'Cuite', '58041000', 'PB', 2, NULL),
        (4, 'Concreto Protendido', 'Rua do Concreto', '320', 'Miramar', 'Cuite', '58041000', 'PB', 2, NULL),
        (5, 'Selecao', 'Rua das Palmeiras', '50', 'Torre', 'Cuite', '58042000', 'PB', 3, NULL),
        (8, 'Divisao nova', NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL);

    SET IDENTITY_INSERT departamentos.divisao OFF;

    SET IDENTITY_INSERT departamentos.empregado ON;

    INSERT INTO departamentos.empregado (
        id_empregado,
        matricula,
        nome,
        cpf,
        endereco_rua,
        endereco_numero,
        endereco_bairro,
        endereco_cidade,
        endereco_cep,
        endereco_uf,
        data_lotacao,
        id_divisao
    )
    VALUES
        (1, '001', 'Eduardo Lima', '11111111111', 'Rua A', '11', 'Bancarios', 'Cuite', '58040000', 'PB', '2022-02-15', 1),
        (2, '002', 'Larissa Alves', '22222222222', 'Rua B', '24', 'Bancarios', 'Cuite', '58040000', 'PB', '2021-08-10', 1),
        (3, '003', 'Gabriel Souza', '33333333333', 'Rua C', '30', 'Bancarios', 'Cuite', '58040000', 'PB', '2023-01-20', 2),
        (4, '004', 'Natalia Costa', '44444444444', 'Rua D', '15', 'Miramar', 'Cuite', '58041000', 'PB', '2020-10-05', 3),
        (5, '005', 'Vinicius Rocha', '55555555555', 'Rua E', '18', 'Miramar', 'Cuite', '58041000', 'PB', '2024-03-01', 4),
        (6, '006', 'Beatriz Martins', '66666666666', 'Rua F', '60', 'Torre', 'Cuite', '58042000', 'PB', '2022-05-18', 5),
        (7, '007', 'Henrique Melo', '77777777777', 'Rua G', '75', 'Torre', 'Cuite', '58042000', 'PB', '2023-07-01', 5);

    SET IDENTITY_INSERT departamentos.empregado OFF;

    -- Atualiza referencias de gerente e chefe apos inserir os empregados.
    UPDATE departamentos.departamento SET id_gerente = 4 WHERE id_departamento = 2;
    UPDATE departamentos.departamento SET id_gerente = 6 WHERE id_departamento = 3;

    UPDATE departamentos.divisao SET id_chefe = 1 WHERE id_divisao = 1;
    UPDATE departamentos.divisao SET id_chefe = 3 WHERE id_divisao = 2;
    UPDATE departamentos.divisao SET id_chefe = 4 WHERE id_divisao = 3;
    UPDATE departamentos.divisao SET id_chefe = 5 WHERE id_divisao = 4;
    UPDATE departamentos.divisao SET id_chefe = 6 WHERE id_divisao = 5;

    SET IDENTITY_INSERT departamentos.vencimento ON;

    INSERT INTO departamentos.vencimento (id_vencimento, nome, tipo, valor)
    VALUES
        (1, 'Salario Base', 'Salario', 5200.00),
        (2, 'Gratificacao Tecnica', 'Gratificacao', 900.00),
        (3, 'Adicional de Periculosidade', 'Adicional', 700.00),
        (4, 'Bonus por Resultado', 'Bonus', 1300.00);

    SET IDENTITY_INSERT departamentos.vencimento OFF;

    SET IDENTITY_INSERT departamentos.desconto ON;

    INSERT INTO departamentos.desconto (id_desconto, nome, tipo, valor)
    VALUES
        (1, 'Contribuicao INSS', 'INSS', 520.00),
        (2, 'Imposto de Renda', 'IRRF', 380.00),
        (3, 'Plano Medico', 'Plano de Saude', 240.00),
        (4, 'Vale Transporte', 'Vale Transporte', 180.00);

    SET IDENTITY_INSERT departamentos.desconto OFF;

    INSERT INTO departamentos.empregado_vencimento (id_empregado, id_vencimento)
    VALUES
        (1, 1),
        (1, 2),
        (2, 1),
        (3, 1),
        (3, 4),
        (4, 1),
        (4, 2),
        (4, 3),
        (5, 1),
        (5, 4),
        (6, 1),
        (6, 2),
        (7, 1),
        (7, 3);

    INSERT INTO departamentos.empregado_desconto (id_empregado, id_desconto)
    VALUES
        (1, 1),
        (1, 2),
        (2, 1),
        (3, 1),
        (3, 3),
        (4, 1),
        (4, 2),
        (4, 4),
        (5, 1),
        (5, 3),
        (6, 1),
        (6, 4),
        (7, 1),
        (7, 2);

    INSERT INTO departamentos.tab_resumo_depto (id_departamento, departamento, [insert])
    VALUES
        (2, 'Calculo Estrutural e Concreto', 2),
        (3, 'Recursos Humanos', 1),
        (1, 'Engenharia', 3);

    DBCC CHECKIDENT ('departamentos.departamento', RESEED, 3);
    DBCC CHECKIDENT ('departamentos.divisao', RESEED, 8);
    DBCC CHECKIDENT ('departamentos.empregado', RESEED, 7);
    DBCC CHECKIDENT ('departamentos.vencimento', RESEED, 4);
    DBCC CHECKIDENT ('departamentos.desconto', RESEED, 4);

    COMMIT TRAN;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRAN;

    THROW;
END CATCH;
GO
