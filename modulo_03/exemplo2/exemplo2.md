# Módulo 06 - Importação e Cruzamento de Dados para Auditoria Tributária

## Apresentação

Nos processos modernos de auditoria tributária, grande parte do trabalho do auditor consiste em integrar informações provenientes de diferentes fontes de dados. Essas informações normalmente são disponibilizadas em arquivos CSV, planilhas eletrônicas, bancos de dados corporativos e bases públicas disponibilizadas pelos órgãos governamentais.

No ambiente das Secretarias de Fazenda (SEFAZ), é comum que uma fiscalização utilize simultaneamente:

- Escrituração Fiscal Digital (EFD ICMS/IPI);
- Cadastro de contribuintes;
- Tabelas oficiais de NCM e CEST;
- Bases da ABCFARMA;
- Tabelas da Receita Federal;
- Convênios CONFAZ;
- Arquivos produzidos pelos próprios contribuintes.

Antes de qualquer análise tributária, essas informações precisam ser importadas, tratadas e consolidadas em uma única base de dados.

Este módulo apresenta um fluxo completo de integração de dados utilizando o SQL Server, demonstrando desde a importação dos arquivos CSV até a construção de uma base consolidada para auditoria tributária.

---

# Objetivos

Ao final deste módulo o aluno será capaz de:

- compreender o processo de integração de dados em projetos de auditoria fiscal;
- importar arquivos CSV utilizando o SQL Server Management Studio;
- utilizar o comando BULK INSERT;
- criar tabelas de apoio;
- relacionar múltiplas bases através de JOIN;
- enriquecer informações da EFD com bases oficiais;
- identificar inconsistências cadastrais e tributárias;
- construir uma base consolidada para análises fiscais.

---

# Cenário Utilizado

Durante todo este módulo será utilizado um cenário inspirado em um ambiente de auditoria tributária.

Serão utilizadas três fontes de dados.

## Base 1

Registro 0200 da Escrituração Fiscal Digital.

```
TB_418_PR_EFD_REGISTRO_0200_IDENTIFICACAO_ITEM_PRODUTO_SERVICO
```

---

## Base 2

Tabela oficial do Anexo V da SEFAZ.

```
anexo_5_sefaz.csv
```

---

## Base 3

Base pública da ABCFARMA.

```
abcfarma.csv
```

---

# Fluxo do Exercício

```
                  Arquivos CSV

          ┌────────────┴────────────┐
          │                         │
          ▼                         ▼
   Anexo V SEFAZ             ABCFARMA

          │                         │

          └────────────┬────────────┘

                       ▼

            Importação SQL Server

                       ▼

            Tabelas de Apoio

                       ▼

          Cruzamento com Registro 0200

                       ▼

        Base Consolidada da Auditoria

                       ▼

      Consultas de Inteligência Fiscal
```

---

# Estrutura do Módulo

## 06.01 – Importação de Arquivos CSV

Importação utilizando SSMS e BULK INSERT.

---

## 06.02 – Cruzamento de Dados com JOIN

Relacionamentos entre as bases.

---

## 06.03 – Consultas de Auditoria Tributária

Construção de consultas utilizadas durante auditorias fiscais.

---

## 06.04 – Casos Práticos

Estudos de caso inspirados em situações reais.

---

## 06.05 – Exercícios Propostos

Exercícios para fixação dos conceitos.

---

## 06.06 – Desafios de ETL e Enriquecimento

Construção de uma base consolidada para auditoria.

---

# Pré-requisitos

Antes de iniciar este módulo recomenda-se que o aluno já tenha estudado:

- Modelagem Relacional;
- SQL Básico;
- CREATE TABLE;
- Tipos de Dados;
- Constraints;
- SELECT;
- WHERE;
- GROUP BY.

---

# Banco de Dados Utilizado

Microsoft SQL Server 2022

As consultas também podem ser adaptadas para:

- PostgreSQL
- MySQL
- Oracle

---

# Público-alvo

Este módulo foi elaborado para:

- Auditores Fiscais;
- Analistas Tributários;
- Desenvolvedores de Sistemas Tributários;
- Engenheiros de Dados;
- Alunos dos cursos da ESAT;
- Profissionais interessados em Inteligência Fiscal.

---

# Competências Desenvolvidas

Ao concluir este módulo o aluno estará apto a desenvolver rotinas de integração de dados semelhantes às utilizadas em projetos de auditoria tributária, empregando técnicas de ETL, enriquecimento de dados e consultas SQL para apoiar a identificação de inconsistências fiscais e a produção de relatórios analíticos.

---

# Próximo Capítulo

➡ **06.01 – Importação de Arquivos CSV**