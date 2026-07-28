create table nfe (
	sqnfe INTEGER IDENTITY,
	valor decimal(20,2),
	dtemissao datetime2,
	chave_estrangeira_empresa INTEGER not null,
	constraint nfe_cp primary key(sqnfe),
	constraint nfe_empresa_ce foreign key (chave_estrangeira_empresa) references empresa(sqempresa)
)

INSERT INTO [dbo].[nfe] ([valor], [dtemissao] ,[chave_estrangeira_empresa])
     VALUES
           (1000.00,'2025-01-02',10)





create table fisc.empresa_fabio (
	sqempresa INTEGER IDENTITY,
	nome varchar(100) not null,
	cnpj char(14),
	dtcriacao datetime2,
	constraint empresa_chave_primaria primary key(sqempresa)
)


cre

insert into empresa (nome,cnpj,dtcriacao) 
	values ('fantasia', '111000100020', '1990-12-01')
insert into empresa (nome,cnpj,dtcriacao) 
	values ('atacdao', '9999999999', '2020-12-01')


create table departamento_fabio_leite (
	codDep char(3) primary key,
	nome varchar(10),
	cod_gerente int,
	--foreign key (cod_gerente) references empregado_fabio_leite(matricula)
);

INSERT INTO departamento_fabio_leite (codDep, Nome)
VALUES
('D1','Computação'),
('D2','Engenharia'),
('D3','Produção');

INSERT INTO departamento_fabio_leite (codDep, Nome)
VALUES
('D4','Transito'),
('D5','Cadastro'),
('D6','Arrecadacao');

INSERT INTO departamento_fabio_leite (codDep, Nome)
VALUES ('D4','Trânsito');

INSERT INTO departamento_fabio_leite (codDep, Nome)
VALUES ('D7','Arrecadacao');

alter table departamento_fabio_leite add constraint uq_nome unique(nome)

select * from departamento_fabio_leite

UPDATE departamento_fabio_leite SET cod_gerente = 1 WHERE codDep = 'D1'
UPDATE departamento_fabio_leite SET cod_gerente = NULL WHERE codDep = 'D1'
UPDATE departamento_fabio_leite SET cod_gerente = 3 WHERE codDep = 'D1'
DELETE empregado_fabio_leite WHERE matricula = 1
DELETE 

-- LEMbrar sempre do fisc
UPDATE empregado_fabio_leite SET salario = salario * 1.1 WHERE departamento = 'D1' ;
UPDATE empregado_fabio_leite SET salario = salario * 1.2 WHERE departamento = 'D2';
UPDATE empregado_fabio_leite SET salario = salario * 1.08 WHERE departamento = 'D3';
select * from empregado_fabio_leite

insert INTO empregado_fabio_leite (matricula, nome, endereco, salario, funcao, departamento) VALUES
(1, 'João da Silva', 'Rua A, 123', 3000.00, 'Analista', 'D1'),
(2, 'Maria Oliveira', 'Rua B, 456', 3500.00, 'Desenvolvedor', 'D2'),
(3, 'Carlos Souza', 'Rua C, 789', 4000.00, 'Gerente', 'D1'),
(4, 'Ana Pereira', 'Rua D, 101', 3200.00, 'Analista', 'D3'),
(5, 'Pedro Santos', 'Rua E, 202', 2800.00, 'Suporte', 'D2');

insert INTO empregado_fabio_leite (matricula, nome, endereco, salario, funcao, departamento) VALUES
(1, 'João da Silva', 'Rua A, 123', 1622.00, 'Analista', 'D1');

alter table departamento_fabio_leite 
	ADD tipo varchar(10) 
alter table departamento_fabio_leite
	drop column tipo;

alter table empregado_fabio_leite
	add constraint verifica_salario_base
	check (salario >= 1621.00)

alter table departamento_fabio_leite 
	add constraint gerente_fk 
	foreign key (cod_gerente) references empregado_fabio_leite(matricula);
-- lembrar sempre do fisc
alter table departamento_fabio_leite
	drop constraint gerente_fk;



drop table empregado_fabio_leite;
drop table departamento_fabio_leite;

create table dbo.empregado_fabio_leite (
	matricula integer primary key,
	nome varchar(100) not null,
	endereco varchar(200),
	salario decimal(10,2),
	funcao varchar(50),
	departamento char(3),
	foreign key (departamento) references departamento_fabio_leite(codDep)
) -- lembrar do fisc

alter table empregado_fabio_leite
	add cpf varchar(11) not null DEFAULT '00000000000';

alter table empregado_fabio_leite
	add cpf_2 varchar(11) unique;

alter table empregado_fabio_leite drop column cpf

alter table empregado_fabio_leite drop constraint DF__empregado_f__cpf__619B8048

select * from empregado_fabio_leite

drop table contribuinte

CREATE TABLE contribuinte (
    id_contribuinte     BIGINT IDENTITY(1,1),
    cnpj_cpf            VARCHAR(14)  NOT NULL,
    razao_social        VARCHAR(150) NOT NULL,
    uf                  CHAR(2)      NOT NULL CONSTRAINT uf_pb DEFAULT ('PB'),
    situacao_cadastral  VARCHAR(20)  NOT NULL CONSTRAINT df_situacao DEFAULT ('ATIVO'),
    CONSTRAINT pk_contribuinte PRIMARY KEY (id_contribuinte),
    CONSTRAINT uq_contribuinte_doc UNIQUE (cnpj_cpf),
    CONSTRAINT ck_situacao CHECK (situacao_cadastral IN ('ATIVO','SUSPENSO','BAIXADO','INAPTO')),
    CONSTRAINT ck_uf CHECK (uf IN ('AC','AL','AM','AP','BA','CE','DF','ES','GO','MA','MG',
                                   'MS','MT','PA','PB','PE','PI','PR','RJ','RN','RO','RR',
                                   'RS','SC','SE','SP','TO'))
);

select * from contribuinte

INSERT INTO [dbo].[contribuinte]
           ([cnpj_cpf]
           ,[razao_social]
           ,[uf]
           ,[situacao_cadastral])
     VALUES
           ('11111111111'
           ,'supermercado'
           ,'PE'
           ,'SUSPENSO')

INSERT INTO [dbo].[contribuinte]
           ([cnpj_cpf]
           ,[razao_social])
     VALUES
           ('0001111000011'
           ,'supermercado')