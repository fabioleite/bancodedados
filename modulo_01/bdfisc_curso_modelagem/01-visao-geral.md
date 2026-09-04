# 01 — Visão geral do BDFisc

## Objetivo

Apresentar a arquitetura lógica do banco de dados fiscal e mostrar como as principais entidades se relacionam.

## Diagrama geral

```mermaid
erDiagram
    CONTRIBUINTE ||--o{ EFD_0000 : "insere escrituração"
    EFD_0000 ||--o{ EFD_0100 : "cadastra contador"
    EFD_0000 ||--o{ EFD_0150 : "cadastra participantes"
    EFD_0000 ||--o{ EFD_0200 : "cadastra produtos"
    EFD_0000 ||--o{ EFD_C100 : "registra documentos"
    EFD_C100 ||--o{ EFD_C170 : "detalha itens"
    EFD_0150 ||--o{ EFD_C100 : "é participante"
    NFE ||--o{ ITEM_NFE : "possui itens"
    EFD_C100 ||..|| NFE : "pode ser cruzado"

    CONTRIBUINTE {
        int sqcontrib PK
        varchar nrcnpj
        varchar nrinscrestadual
        varchar nocontribuinte
    }

    EFD_0000 {
        int sqcontrib PK
        date dtinicial
        date dtfinal
        varchar nrcnpj
        varchar nrinscrestadual
        char sguf
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

    EFD_C100 {
        bigint sqnfoutra PK
        int sqcontrib FK
        int sqparticip FK
        varchar nrchavenfe
        date dtemissao
        decimal vltotalnf
    }

    EFD_C170 {
        bigint sqitemnfoutra PK
        bigint sqnfoutra FK
        bigint sqidentitem
        decimal qtitemdocfisc
        decimal vlitemdocfisc
    }

    NFE {
        bigint sqnfe PK
        varchar nrchaveacesso
        int tpnfe
        decimal vltotalnota
    }

    ITEM_NFE {
        bigint sqitemnfe PK
        bigint sqnfe FK
        varchar cdncm
        varchar cdcfop
        decimal vlproduto
    }
```

## Como interpretar

- A base do modelo começa em EFD_0000, que representa a abertura da escrituração.
- A entidade EFD_0150 registra participantes envolvidos na operação fiscal.
- A entidade EFD_0200 organiza a base de produtos e mercadorias.
- EFD_C100 representa o documento fiscal em nível de cabeçalho.
- EFD_C170 detalha cada item do documento.
- NFE e ITEM_NFE formam o núcleo das notas eletrônicas.

## Conclusão

O BDFisc pode ser entendido como um conjunto de camadas:

1. cadastro e identificação;
2. documentos fiscais;
3. itens e mercadorias;
4. cruzamento entre escrituração e notas eletrônicas.

Essa visão é essencial para a auditoria tributária e para a análise de dados fiscais em ambiente analítico.
