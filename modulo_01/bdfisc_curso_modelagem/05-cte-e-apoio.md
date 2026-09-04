# 05 — CTe e estruturas auxiliares

## Visão do modelo de transporte

```mermaid
erDiagram
    CTE ||--o{ CTE_NFE : "transporta notas"
    CTE ||--o{ CTE_VEIC : "descreve veículo"
    CTE ||--o{ CTE_PROPVEIC : "identifica proprietários"
    CTE ||--o{ CTE_UFDEST : "define UF de destino"
    CTE ||--o{ CTE_TERCEIROS : "inclui terceiros"

    CTE {
        bigint sqcte PK
        varchar nrchavecte
        varchar nrcte
        date dtemissao
        varchar nrfantasia
        decimal vltotal
    }

    CTE_NFE {
        bigint sqctenfe PK
        bigint sqcte FK
        varchar nrchavenfe
    }

    CTE_VEIC {
        bigint sqveic PK
        bigint sqcte FK
        varchar nrrenavam
        varchar nrplaca
        varchar nrmotorista
    }

    CTE_PROPVEIC {
        bigint sqpropveic PK
        bigint sqcte FK
        varchar nrcnpj
        varchar nopropietario
    }

    CTE_UFDEST {
        bigint squfdest PK
        bigint sqcte FK
        varchar sguf
    }

    CTE_TERCEIROS {
        bigint sqterceiros PK
        bigint sqcte FK
        varchar nrcnpj
        varchar noparticipante
    }
```

## Comentário

O CTe é um documento complementar ligado ao transporte de cargas. Ele não substitui a NF-e, mas pode transportar ou referenciar documentos fiscais gerados no processo logístico.

A estrutura do modelo mostra que o banco não é somente de documentos fiscais internos: ele também registra carga, transporte, locais e terceiros envolvidos no fluxo.
