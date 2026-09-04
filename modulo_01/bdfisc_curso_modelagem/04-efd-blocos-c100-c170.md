# 04 — Blocos C100 e C170 da EFD

## Bloco de cabeçalho e detalhe

```mermaid
erDiagram
    EFD_C100 ||--o{ EFD_C101 : "informações complementares"
    EFD_C100 ||--o{ EFD_C105 : "operações por UF"
    EFD_C100 ||--o{ EFD_C110 : "informações complementares"
    EFD_C100 ||--o{ EFD_C140 : "faturas e títulos"
    EFD_C100 ||--o{ EFD_C160 : "volumes transportados"
    EFD_C100 ||--o{ EFD_C170 : "itens do documento"
    EFD_C170 ||--o{ EFD_C171 : "complementos do item"

    EFD_C100 {
        bigint sqnfoutra PK
        int sqcontrib FK
        int sqparticip FK
        varchar nrchavenfe
        varchar nrseriedocfisc
        date dtemissao
        decimal vltotalnf
        decimal vlicms
        decimal vlpis
        decimal vlcofins
    }

    EFD_C170 {
        bigint sqitemnfoutra PK
        bigint sqnfoutra FK
        int nritemdocfisc
        decimal qtitemdocfisc
        decimal vlitemdocfisc
        decimal vlicms
        decimal vlpis
        decimal vlcofins
        decimal vlbasecalcicms
    }

    EFD_C171 {
        int sqitemnfoutra FK
        int sqarmazcomb
        varchar cdcombustivel
        decimal vlquantidade
    }
```

## Interpretação

### EFD_C100

- É o registro de cabeçalho do documento fiscal.
- Inclui dados do emissor, destinatário, chave da NF-e, emissões e totais tributários.

### EFD_C170

- Contém os itens do documento fiscal.
- É onde ficam as quantidades, valores e tributos por produto/serviço.

### Registros complementares

- C101, C105, C110, C140, C160 e C171 complementam informações de acordo com a natureza da operação.
- Isso mostra que o modelo fiscal não é linear: há blocos específicos dependendo do tipo de documento e do contexto tributário.

## Exemplo de regra de negócio

Para um documento de saída:

1. o registro de cabeçalho entra em EFD_C100;
2. cada linha do documento entra em EFD_C170;
3. detalhes adicionais podem ser anexados em registros tipo C171, C140 ou C160.

Assim, a modelagem representa a estrutura real de documentos fiscais complexos.
