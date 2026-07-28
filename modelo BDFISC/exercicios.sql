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
	cod_gerente int
)

create table empregado_fabio_leite (
	matricula integer primary key,
	nome varchar(100) not null,
	endereco varchar(200),
	salario decimal(10,2),
	funcao varchar(50),
	departamento char(3),
	foreign key (departamento) references departamento_fabio_leite(codDep)
) -- lembrar do fisc

drop table empregado_fabio_leite

insert INTO empregado_fabio_leite (matricula, nome, endereco, salario, funcao, departamento) VALUES
(1, 'João da Silva', 'Rua A, 123', 3000.00, 'Analista', 'D01'),
(2, 'Maria Oliveira', 'Rua B, 456', 3500.00, 'Desenvolvedor', 'D02'),
(3, 'Carlos Souza', 'Rua C, 789', 4000.00, 'Gerente', 'D01'),
(4, 'Ana Pereira', 'Rua D, 101', 3200.00, 'Analista', 'D03'),
(5, 'Pedro Santos', 'Rua E, 202', 2800.00, 'Suporte', 'D02');
