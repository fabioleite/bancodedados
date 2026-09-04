# 03 — Seções principais da EFD

## Estrutura lógica da escrituração

```mermaid
erDiagram
    EFD_0000 ||--o{ EFD_0100 : "identifica contador"
    EFD_0000 ||--o{ EFD_0150 : "cadastro de participantes"
    EFD_0000 ||--o{ EFD_0200 : "cadastro de mercadorias"
    EFD_0000 ||--o{ EFD_0300 : "cadastro de bens/serviços"
    EFD_0000 ||--o{ EFD_0500 : "cadastro de contas"

    EFD_0000 {
        int sqcontrib PK
        varchar nrcnpj
        varchar nrinscrestadual
        varchar nocontribuinte
        date dtinicial
        date dtfinal
    }

    EFD_0100 {
        int sqcontador PK
        int sqcontrib FK
        varchar nocontador
        varchar nrcnpj
        varchar nrcrc
    }

    EFD_0150 {
        int sqparticip PK
        int sqcontrib FK
        varchar noparticipante
        varchar nrcnpj
        varchar nrinscrestadual
    }

    EFD_0200 {
        int sqitemmerc PK
        int sqcontrib FK
        varchar cditem
        varchar dsitem
        varchar cdundmedida
    }

    EFD_0300 {
        int sqprodserv PK
        int sqcontrib FK
        varchar cdprodserv
        varchar dsprodserv
    }

    EFD_0500 {
        int sqplanoconta PK
        int sqcontrib FK
        varchar dshistorico
        varchar cdcodconta
    }
```

## Função das seções

### EFD_0000

- Registro de abertura da escrituração.
- Define o contribuinte, o período de apuração e a UF.

### EFD_0100

- Cadastro do contador ou responsável pela escrituração.
- Muito importante para atribuição técnica e rastreabilidade.

### EFD_0150

- Cadastro de participantes do negócio.
- Inclui clientes, fornecedores, tomadores e prestadores.

### EFD_0200 / EFD_0300

- Representam a base de mercadorias e serviços cadastrados.
- Permitem padronizar o item na análise fiscal.

### EFD_0500

- Registra contas e eventos contábeis e fiscais.
- Complementa o contexto da escrituração.

## Objetivo didático

Essas tabelas funcionam como o “cadastro mestre” da EFD. Sem elas, o banco teria dificuldade de contextualizar documentos, participantes e produtos.
