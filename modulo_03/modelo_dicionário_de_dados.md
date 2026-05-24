# Modelo de Dicionário de Dados para Modelo Lógico Relacional

## Objetivo

Este documento apresenta um modelo de dicionário de dados para descrever estruturas de um modelo lógico relacional. O objetivo é padronizar a documentação das tabelas, atributos, relacionamentos e restrições do banco de dados.

---

# 1. Informações Gerais da Tabela

| Campo | Descrição |
|---|---|
| Nome da Tabela | Nome físico da tabela no banco de dados |
| Descrição | Objetivo da tabela no sistema |
| Responsável | Setor, módulo ou equipe responsável |
| Observações | Regras e observações relevantes |

---

# 2. Estrutura dos Atributos

## Tabela: CLIENTE

**Descrição:** Armazena informações cadastrais dos clientes do sistema.

| Campo | Tipo de Dado | Tamanho | PK | FK | Nulo | Único | Default | Descrição | Regra de Negócio |
|---|---|---|---|---|---|---|---|---|---|
| id_cliente | INTEGER | — | Sim | Não | Não | Sim | Auto Increment | Identificador do cliente | Gerado automaticamente |
| nome | VARCHAR | 150 | Não | Não | Não | Não | — | Nome completo do cliente | Deve possuir nome e sobrenome |
| cpf | CHAR | 11 | Não | Não | Não | Sim | — | CPF do cliente | Não pode existir duplicidade |
| email | VARCHAR | 120 | Não | Não | Sim | Sim | — | E-mail do cliente | Deve possuir formato válido |
| data_nascimento | DATE | — | Não | Não | Sim | Não | — | Data de nascimento | Deve ser menor que a data atual |
| telefone | VARCHAR | 20 | Não | Não | Sim | Não | — | Telefone de contato | Formato nacional |
| status | CHAR | 1 | Não | Não | Não | Não | 'A' | Situação do cliente | A = Ativo / I = Inativo |

---

# 3. Relacionamentos

| Tabela Origem | Campo FK | Tabela Destino | Campo PK | Cardinalidade | Descrição |
|---|---|---|---|---|---|
| PEDIDO | id_cliente | CLIENTE | id_cliente | N:1 | Um pedido pertence a um cliente |
| HOTEL | id_cidade | CIDADE | id_cidade | N:1 | Um hotel pertence a uma cidade |

---

# 4. Restrições e Integridade

## Restrições de Domínio

| Campo | Restrição |
|---|---|
| status | Valores permitidos: A, I |
| cpf | Deve conter apenas números |
| email | Deve possuir formato válido |

---

## Restrições de Integridade Referencial

| Chave Estrangeira | Regra ON DELETE | Regra ON UPDATE |
|---|---|---|
| pedido.id_cliente | RESTRICT | CASCADE |
| hotel.id_cidade | RESTRICT | CASCADE |

---

# 5. Exemplo Simplificado para Atividades Acadêmicas

## Tabela: HOTEL

**Descrição:** Armazena os dados dos hotéis cadastrados no sistema.

| Campo | Tipo | Tamanho | PK | FK | Nulo | Descrição |
|---|---|---|---|---|---|---|
| id_hotel | INTEGER | — | Sim | Não | Não | Identificador do hotel |
| nome | VARCHAR | 120 | Não | Não | Não | Nome do hotel |
| categoria | INTEGER | — | Não | Não | Não | Quantidade de estrelas |
| id_cidade | INTEGER | — | Não | Sim | Não | Cidade onde o hotel está localizado |
| telefone | VARCHAR | 20 | Não | Não | Sim | Telefone do hotel |

---

## Tabela: CIDADE

**Descrição:** Armazena os dados das cidades turísticas.

| Campo | Tipo | Tamanho | PK | FK | Nulo | Descrição |
|---|---|---|---|---|---|---|
| id_cidade | INTEGER | — | Sim | Não | Não | Identificador da cidade |
| nome | VARCHAR | 100 | Não | Não | Não | Nome da cidade |
| estado | CHAR | 2 | Não | Não | Não | Sigla do estado |
| pais | VARCHAR | 60 | Não | Não | Não | País da cidade |

---

# 6. Convenções Recomendadas

## Convenções de Nomenclatura

- Utilizar nomes descritivos para tabelas e atributos
- Padronizar nomes em singular ou plural
- Utilizar prefixo `id_` ou `cod_` para chaves primárias
- Chaves estrangeiras devem possuir o mesmo nome da chave primária referenciada
- Evitar espaços e caracteres especiais
- Preferir nomes em minúsculo com underscore (`snake_case`)

---

## Tipos de Dados Recomendados

| Tipo | Utilização |
|---|---|
| INTEGER | Identificadores numéricos |
| VARCHAR | Textos variáveis |
| CHAR | Campos de tamanho fixo |
| DATE | Datas |
| DATETIME | Data e hora |
| DECIMAL | Valores monetários. Ex. `DECIMAL(15, 2)` |
| BOOLEAN | Valores lógicos |
| TEXT | Textos ou varchar muito longos|

---

# 7. Template Resumido

## Estrutura Base

```text
Tabela: NOME_TABELA

Descrição:
Descrição da finalidade da tabela.

| Campo | Tipo | Tam | PK | FK | Nulo | Único | Default | Descrição |
|-------|------|-----|----|----|------|--------|----------|------------|
|       |      |     |    |    |      |        |          |            |
```

---

# 8. Sugestão de Organização do Repositório no GitHub

```text
docs/
├── dicionario_dados.md
├── modelo_logico.png
├── modelo_fisico.sql
└── README.md
```