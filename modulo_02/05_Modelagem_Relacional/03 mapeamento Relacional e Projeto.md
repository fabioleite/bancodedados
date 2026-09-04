# Módulo: Do MER para o Modelo Relacional — Regras de Mapeamento

**Curso:** Banco de Dados Relacionais aplicado à Administração Tributária
**Público-alvo:** Profissionais da Secretaria de Estado da Fazenda da Paraíba (SEFAZ-PB)
**SGBD utilizado:** Microsoft SQL Server (T-SQL) — ferramenta: SQL Server Management Studio (SSMS)
**Carga horária sugerida:** 6 horas (3h teoria + 3h prática)

---

## Sumário

1. [Objetivos do Módulo](#1-objetivos-do-módulo)
2. [Recapitulação Rápida: MER e Modelo Relacional](#2-recapitulação-rápida-mer-e-modelo-relacional)
3. [Visão Geral das Regras de Mapeamento](#3-visão-geral-das-regras-de-mapeamento)
4. [Regra 1 — Entidade Forte → Tabela](#4-regra-1--entidade-forte--tabela)
5. [Regra 2 — Atributo Multivalorado → Tabela Separada](#5-regra-2--atributo-multivalorado--tabela-separada)
6. [Regra 3 — Relacionamento 1:N → Chave Estrangeira no Lado "N"](#6-regra-3--relacionamento-1n--chave-estrangeira-no-lado-n)
7. [Regra 4 — Relacionamento N:N → Tabela Associativa](#7-regra-4--relacionamento-nn--tabela-associativa)
8. [Regra 5 — Entidade Fraca → Tabela com Chave Dependente](#8-regra-5--entidade-fraca--tabela-com-chave-dependente)
9. [Regra 6 — Autorrelacionamento → FK para a Própria Tabela](#9-regra-6--autorrelacionamento--fk-para-a-própria-tabela)
10. [Regra 7 — Relacionamento 1:1 → FK com UNIQUE](#10-regra-7--relacionamento-11--fk-com-unique)
11. [Consolidando: Modelo Conceitual Único (EFD + NF-e)](#11-consolidando-modelo-conceitual-único-efd--nf-e)
12. [Roteiro Prático — Script T-SQL Completo](#12-roteiro-prático--script-t-sql-completo)
13. [Exercícios Práticos](#13-exercícios-práticos)
14. [Glossário](#14-glossário)
15. [Referências](#15-referências)

---

## 1. Objetivos do Módulo

Ao final deste módulo, o participante será capaz de:

- Aplicar, com segurança, cada uma das **sete regras de mapeamento** de um Modelo Entidade-Relacionamento (MER) para um esquema relacional.
- Reconhecer, em documentos fiscais reais (**NF-e**, **EFD**, **CT-e**), qual regra de mapeamento se aplica a cada situação de modelagem.
- Justificar tecnicamente as decisões de modelagem tomadas (por que uma tabela associativa, e não uma FK direta; por que uma entidade fraca, e não uma tabela independente).
- Implementar, em **T-SQL (SQL Server)**, um esquema relacional único que integra exemplos de NF-e e EFD, aplicando todas as regras estudadas.

---

## 2. Recapitulação Rápida: MER e Modelo Relacional

| Conceito no MER | Conceito no Modelo Relacional |
|---|---|
| Entidade | Tabela (relação) |
| Atributo | Coluna |
| Atributo identificador | Chave primária |
| Relacionamento | Chave estrangeira (ou tabela associativa, no caso N:N) |
| Ocorrência de entidade | Tupla (linha) |

O MER descreve o domínio de negócio de forma **visual e conceitual** — por exemplo, "uma NF-e é emitida por um Contribuinte". O Modelo Relacional traduz essa descrição em **tabelas, colunas e chaves** que o SQL Server consegue armazenar e validar. As regras de mapeamento são a "ponte" entre os dois mundos.

---

## 3. Visão Geral das Regras de Mapeamento

| Regra | Situação no MER | Solução no Modelo Relacional |
|---|---|---|
| **1** | Entidade forte | Vira uma tabela; atributo identificador vira `PRIMARY KEY` |
| **2** | Atributo multivalorado | Vira uma tabela separada, com FK para a entidade original |
| **3** | Relacionamento 1:N | Chave primária do lado "1" é replicada como FK no lado "N" |
| **4** | Relacionamento N:N | Cria-se uma tabela associativa com FK para as duas entidades |
| **5** | Entidade fraca | Vira uma tabela cuja chave inclui (ou depende de) a chave da entidade da qual depende |
| **6** | Autorrelacionamento | FK aponta para a própria tabela |
| **7** | Relacionamento 1:1 | FK em um dos lados, com constraint `UNIQUE` adicional |

Cada uma dessas regras é detalhada a seguir, com um exemplo completo baseado em **NF-e** e/ou **EFD**.

---

## 4. Regra 1 — Entidade Forte → Tabela

**Definição:** toda entidade forte (que tem existência independente, com identidade própria) vira uma tabela. Seus atributos simples viram colunas, e o atributo identificador vira a `PRIMARY KEY`.

### Exemplo detalhado: a entidade "Nota Fiscal Eletrônica (NF-e)"

No MER, a NF-e é modelada como uma entidade forte, com estes atributos:

```
Entidade: Nota Fiscal Eletrônica
  - chave_acesso (identificador, 44 dígitos)
  - numero_nf
  - serie
  - data_emissao
  - valor_total
  - situacao (autorizada, cancelada, denegada)
```

**Aplicando a Regra 1:**

```sql
CREATE TABLE nfe (
    id_nfe          BIGINT IDENTITY(1,1) NOT NULL,   -- chave substituta (surrogate key)
    chave_acesso    CHAR(44)      NOT NULL,           -- identificador natural do MER
    numero_nf        INT           NOT NULL,
    serie            SMALLINT      NOT NULL,
    data_emissao     DATE          NOT NULL,
    valor_total      NUMERIC(15,2) NOT NULL,
    situacao          VARCHAR(20)   NOT NULL CONSTRAINT df_nfe_situacao DEFAULT ('AUTORIZADA'),
    CONSTRAINT pk_nfe PRIMARY KEY (id_nfe),
    CONSTRAINT uq_nfe_chave UNIQUE (chave_acesso)
);
```

> **Nota de modelagem:** o identificador natural da entidade no mundo real é a `chave_acesso` (44 dígitos, definida pelo layout da NF-e). Ainda assim, é comum escolher uma **chave substituta** (`id_nfe IDENTITY`) como `PRIMARY KEY`, mantendo `chave_acesso` como chave alternativa (`UNIQUE`). Isso torna os `JOIN`s mais eficientes (comparação de `BIGINT` é mais rápida que de `CHAR(44)`) sem abrir mão da unicidade do identificador oficial do documento.

O mesmo raciocínio se aplica a outras entidades fortes do domínio fiscal:

```sql
CREATE TABLE contribuinte (
    id_contribuinte  BIGINT IDENTITY(1,1) NOT NULL,
    cnpj_cpf          VARCHAR(14)  NOT NULL,
    razao_social       VARCHAR(150) NOT NULL,
    uf                  CHAR(2)      NOT NULL,
    CONSTRAINT pk_contribuinte PRIMARY KEY (id_contribuinte),
    CONSTRAINT uq_contribuinte_doc UNIQUE (cnpj_cpf)
);
```

---

## 5. Regra 2 — Atributo Multivalorado → Tabela Separada

**Definição:** um atributo multivalorado (que pode ter mais de um valor para a mesma ocorrência de entidade) **não pode virar uma única coluna** — isso violaria a 1ª Forma Normal. Ele vira uma nova tabela, com FK para a entidade original.

### Exemplo detalhado: as "Duplicatas" (parcelas de pagamento) da NF-e

O layout oficial da NF-e prevê um grupo chamado **`cobr`** (cobrança), que pode conter **várias duplicatas** (`dup`) — uma para cada parcela de pagamento do mesmo documento fiscal. No MER, isso é representado como um atributo multivalorado da entidade NF-e:

```
Entidade: Nota Fiscal Eletrônica
  - chave_acesso (identificador)
  - valor_total
  - duplicata (MULTIVALORADO: numero_duplicata, data_vencimento, valor_duplicata)
```

**Por que não pode ser uma única coluna?** Se tentássemos representar como:

```
❌ ERRADO — viola a 1ª Forma Normal:
nfe (id_nfe, chave_acesso, valor_total,
     duplicatas = '001/15-08-2026/500.00; 002/15-09-2026/500.00')
```

... a coluna `duplicatas` deixaria de ser atômica, tornando impossível consultar, indexar ou validar cada parcela individualmente (por exemplo, "quais duplicatas vencem esta semana?" exigiria manipulação de texto em vez de uma consulta SQL direta).

**Aplicando a Regra 2** — cria-se a tabela `duplicata_nfe`:

```sql
CREATE TABLE duplicata_nfe (
    id_duplicata       BIGINT IDENTITY(1,1) NOT NULL,
    id_nfe              BIGINT         NOT NULL,   -- FK para a entidade original
    numero_duplicata     VARCHAR(10)    NOT NULL,
    data_vencimento       DATE           NOT NULL,
    valor_duplicata        NUMERIC(15,2)  NOT NULL,
    CONSTRAINT pk_duplicata_nfe PRIMARY KEY (id_duplicata),
    CONSTRAINT ck_duplicata_valor_positivo CHECK (valor_duplicata >= 0),
    CONSTRAINT fk_duplicata_nfe FOREIGN KEY (id_nfe)
        REFERENCES nfe (id_nfe) ON DELETE CASCADE
);
```

> **Discussão em turma:** repare que `duplicata_nfe` acabou com uma estrutura muito parecida com a de uma **entidade fraca** (Regra 5) — sua existência depende inteiramente de uma NF-e. Isso não é coincidência: **atributos multivalorados frequentemente se transformam em entidades fracas** quando modelados com mais rigor, pois o "número da duplicata" (`001`, `002`...) só é único **dentro do contexto de uma NF-e específica**, não globalmente. Veremos essa nuance com mais detalhe na Regra 5.

---

## 6. Regra 3 — Relacionamento 1:N → Chave Estrangeira no Lado "N"

**Definição:** em um relacionamento 1:N, a chave primária do lado "1" é replicada como chave estrangeira no lado "N".

### Exemplo detalhado 1: Contribuinte emite NF-e

```
Contribuinte (1) ── emite ──> (N) Nota Fiscal Eletrônica
```

```sql
CREATE TABLE nfe (
    id_nfe                      BIGINT IDENTITY(1,1) NOT NULL,
    chave_acesso                 CHAR(44)      NOT NULL,
    id_contribuinte_emitente     BIGINT         NOT NULL,   -- FK: PK de contribuinte replicada aqui
    valor_total                   NUMERIC(15,2)  NOT NULL,
    CONSTRAINT pk_nfe PRIMARY KEY (id_nfe),
    CONSTRAINT uq_nfe_chave UNIQUE (chave_acesso),
    CONSTRAINT fk_nfe_emitente FOREIGN KEY (id_contribuinte_emitente)
        REFERENCES contribuinte (id_contribuinte)
);
```

### Exemplo detalhado 2: a hierarquia de blocos e registros da EFD

Este é um dos exemplos mais ricos de relacionamento 1:N no contexto fiscal, porque **o próprio layout do SPED já é hierárquico por natureza**. Um arquivo de EFD ICMS/IPI organiza seus dados em **registros pai e filho**: por exemplo, dentro do **Bloco C** (Documentos Fiscais):

```
Registro C100 (Documento Fiscal — cabeçalho da NF-e escriturada)  (1)
        │
        └──< Registro C170 (Itens do documento fiscal)  (N)
```

Um mesmo registro `C100` pode ter **vários** registros `C170` filhos (um para cada item/produto do documento), mas cada `C170` pertence a exatamente um `C100`. É um relacionamento 1:N clássico:

```sql
CREATE TABLE efd_registro_c100 (
    id_c100              BIGINT IDENTITY(1,1) NOT NULL,
    id_contribuinte       BIGINT         NOT NULL,
    chave_acesso_nfe       CHAR(44)       NOT NULL,
    periodo_apuracao        CHAR(7)        NOT NULL,   -- formato 'MM/AAAA'
    valor_total_documento     NUMERIC(15,2)  NOT NULL,
    CONSTRAINT pk_efd_c100 PRIMARY KEY (id_c100),
    CONSTRAINT fk_c100_contribuinte FOREIGN KEY (id_contribuinte)
        REFERENCES contribuinte (id_contribuinte)
);

CREATE TABLE efd_registro_c170 (
    id_c170          BIGINT IDENTITY(1,1) NOT NULL,
    id_c100           BIGINT         NOT NULL,   -- FK: PK de efd_registro_c100 replicada aqui
    numero_item        INT            NOT NULL,
    codigo_produto       VARCHAR(60)    NOT NULL,
    cfop                  CHAR(4)        NOT NULL,
    valor_item              NUMERIC(15,2)  NOT NULL,
    CONSTRAINT pk_efd_c170 PRIMARY KEY (id_c170),
    CONSTRAINT ck_c170_valor_positivo CHECK (valor_item >= 0),
    CONSTRAINT fk_c170_c100 FOREIGN KEY (id_c100)
        REFERENCES efd_registro_c100 (id_c100) ON DELETE CASCADE
);
```

> **Ponte com o módulo anterior:** repare que `efd_registro_c100.chave_acesso_nfe` armazena a mesma chave de acesso presente na tabela `nfe`. Isso é proposital: no **cruzamento de malha fiscal**, uma das consultas mais comuns é verificar se toda `nfe` autorizada possui um `efd_registro_c100` correspondente (visto no módulo de Restrições e Integridade). Formalmente, poderíamos até substituir `chave_acesso_nfe` por uma `FOREIGN KEY` direta para `nfe.id_nfe` — isso será proposto como exercício.

---

## 7. Regra 4 — Relacionamento N:N → Tabela Associativa

**Definição:** cria-se uma nova tabela cuja chave primária é composta pelas chaves estrangeiras das duas entidades envolvidas — essa tabela pode ter também atributos próprios do relacionamento.

### Exemplo detalhado: CT-e transporta múltiplas NF-e, e uma NF-e pode ser transportada por múltiplos CT-e

Na prática do transporte de cargas, é comum que:

- Um único **CT-e** transporte **várias NF-e** ao mesmo tempo (frete consolidado de várias notas em uma mesma carga).
- Uma mesma **NF-e** seja transportada por **mais de um CT-e** (fracionamento de carga entre veículos ou etapas de transporte, comum em operações interestaduais com transbordo).

```
CT-e (N) ── transporta ── (N) Nota Fiscal Eletrônica
```

Isso é um relacionamento **N:N genuíno** — nenhum dos dois lados pode simplesmente "guardar o ID do outro" numa única coluna. **Aplicando a Regra 4:**

```sql
CREATE TABLE cte (
    id_cte                       BIGINT IDENTITY(1,1) NOT NULL,
    chave_acesso                  CHAR(44)       NOT NULL,
    id_contribuinte_emitente       BIGINT         NOT NULL,
    valor_frete                      NUMERIC(15,2)  NOT NULL,
    CONSTRAINT pk_cte PRIMARY KEY (id_cte),
    CONSTRAINT uq_cte_chave UNIQUE (chave_acesso),
    CONSTRAINT fk_cte_emitente FOREIGN KEY (id_contribuinte_emitente)
        REFERENCES contribuinte (id_contribuinte)
);
GO

-- Tabela associativa: representa o relacionamento N:N "CT-e transporta NF-e"
CREATE TABLE cte_nfe_transportada (
    id_cte                 BIGINT         NOT NULL,
    id_nfe                  BIGINT         NOT NULL,
    valor_mercadoria_transportada  NUMERIC(15,2)  NOT NULL,   -- atributo do próprio relacionamento
    CONSTRAINT pk_cte_nfe_transportada PRIMARY KEY (id_cte, id_nfe),  -- chave composta
    CONSTRAINT ck_valor_transportado_positivo CHECK (valor_mercadoria_transportada >= 0),
    CONSTRAINT fk_ctenfe_cte FOREIGN KEY (id_cte)
        REFERENCES cte (id_cte),
    CONSTRAINT fk_ctenfe_nfe FOREIGN KEY (id_nfe)
        REFERENCES nfe (id_nfe)
);
```

> **Por que a tabela associativa tem um atributo próprio (`valor_mercadoria_transportada`)?** Porque o **valor de mercadoria transportado** faz sentido apenas na combinação específica "este CT-e transportando esta NF-e" — não é um atributo nem do CT-e isoladamente (que pode ter frete de várias notas), nem da NF-e isoladamente (que pode ser transportada em etapas por CT-es diferentes, cada um levando uma fração do valor). Esse é um sinal claro de que o atributo pertence ao **relacionamento**, e não a nenhuma das duas entidades.

> **Consulta típica de fiscalização habilitada por esse modelo:**
> ```sql
> -- Todas as NF-e que foram fracionadas em mais de um CT-e
> SELECT id_nfe, COUNT(*) AS qtd_ctes
> FROM cte_nfe_transportada
> GROUP BY id_nfe
> HAVING COUNT(*) > 1;
> ```

---

## 8. Regra 5 — Entidade Fraca → Tabela com Chave Dependente

**Definição:** uma entidade fraca não tem identidade própria — sua existência depende de outra entidade (a "entidade forte" ou proprietária). Sua chave primária inclui, ou depende diretamente, da chave estrangeira que a liga à entidade da qual depende.

### Exemplo detalhado: os "Eventos da NF-e"

O Ambiente Nacional da NF-e permite o registro de **eventos** associados a uma NF-e já autorizada: **Cancelamento**, **Carta de Correção Eletrônica (CC-e)**, **Manifestação do Destinatário**, entre outros. Cada evento possui um **número sequencial (`nSeqEvento`)** que é único **apenas dentro do contexto de uma mesma chave de acesso** — ou seja, duas NF-e diferentes podem, cada uma, ter um evento de número sequencial `1`, sem qualquer conflito, pois o número só faz sentido *relativo à NF-e a que pertence*.

```
Entidade fraca: Evento da NF-e
  - numero_sequencial_evento (só é único DENTRO de uma NF-e)
  - tipo_evento (CANCELAMENTO, CC-E, MANIFESTACAO_DESTINATARIO)
  - data_hora_evento
  - descricao_evento
```

Isso é exatamente a definição de entidade fraca: **sem saber a qual NF-e o evento pertence, o número sequencial sozinho não identifica nada**.

**Aplicando a Regra 5:**

```sql
CREATE TABLE evento_nfe (
    id_evento                 BIGINT IDENTITY(1,1) NOT NULL,  -- chave substituta (opção de implementação)
    id_nfe                     BIGINT       NOT NULL,          -- FK obrigatória: entidade da qual depende
    numero_sequencial_evento     INT          NOT NULL,
    tipo_evento                    VARCHAR(30)  NOT NULL,
    data_hora_evento                 DATETIME2    NOT NULL,
    descricao_evento                   VARCHAR(500) NULL,
    CONSTRAINT pk_evento_nfe PRIMARY KEY (id_evento),
    -- a unicidade "real" do MER é garantida aqui, não pela PK:
    CONSTRAINT uq_evento_por_nfe UNIQUE (id_nfe, numero_sequencial_evento),
    CONSTRAINT ck_tipo_evento CHECK (tipo_evento IN ('CANCELAMENTO','CCE','MANIFESTACAO_DESTINATARIO')),
    CONSTRAINT fk_evento_nfe FOREIGN KEY (id_nfe)
        REFERENCES nfe (id_nfe) ON DELETE CASCADE
);
```

> **Duas formas válidas de implementar uma entidade fraca:**
> 1. **Chave composta "pura"**: `PRIMARY KEY (id_nfe, numero_sequencial_evento)` — mais fiel à teoria, mas gera FKs compostas em qualquer tabela "neta" (que dependa de `evento_nfe`).
> 2. **Chave substituta + `UNIQUE` composto** (a opção usada acima): mais prática no dia a dia — simplifica `JOIN`s futuros — mas exige a constraint `UNIQUE (id_nfe, numero_sequencial_evento)` para preservar a regra de negócio original do MER (o número sequencial só é único dentro da NF-e). **Sem essa `UNIQUE`, a entidade deixaria de respeitar a definição de entidade fraca.**

> **Ligação com a Regra 2:** como comentado na seção 5, a tabela `duplicata_nfe` também poderia (e, rigorosamente, deveria) ser modelada como entidade fraca, com `UNIQUE (id_nfe, numero_duplicata)` — o número de uma duplicata só é único dentro da NF-e a que pertence, exatamente como o `numero_sequencial_evento`.

---

## 9. Regra 6 — Autorrelacionamento → FK para a Própria Tabela

**Definição:** quando uma entidade se relaciona consigo mesma, a chave estrangeira aponta para a chave primária da mesma tabela.

### Exemplo detalhado: NF-e que referencia outra NF-e

O layout da NF-e possui o grupo **`NFref`** (Notas Fiscais Referenciadas), usado quando um documento faz menção a outro documento fiscal previamente emitido. Os casos mais comuns:

- Uma **NF-e de devolução** referencia a **NF-e de venda original**.
- Uma **NF-e complementar** (usada para complementar valor ou quantidade) referencia a **NF-e original** que está sendo complementada.

```
Nota Fiscal Eletrônica ── referencia ── Nota Fiscal Eletrônica
        (nota de devolução/complementar)      (nota original)
```

Isso é um relacionamento da entidade `NF-e` **consigo mesma** — a mesma tabela `nfe` desempenha dois papéis diferentes na mesma relação: "documento que referencia" e "documento referenciado".

**Aplicando a Regra 6:**

```sql
ALTER TABLE nfe
ADD id_nfe_referenciada BIGINT NULL;   -- NULL = nota "normal", sem referência a outra

ALTER TABLE nfe
ADD CONSTRAINT fk_nfe_referenciada
    FOREIGN KEY (id_nfe_referenciada) REFERENCES nfe (id_nfe);
```

> **Por que a coluna permite `NULL`?** Porque a maior parte das NF-e (vendas normais) **não** referencia nenhuma outra nota — apenas devoluções, complementares e alguns outros casos específicos preenchem esse campo. Isso é típico de autorrelacionamentos opcionais (compare com `auditor_fiscal.id_auditor_supervisor`, visto no módulo anterior, onde nem todo auditor tem um supervisor direto).

> **Consulta típica de fiscalização habilitada por esse modelo:**
> ```sql
> -- Localizar a nota de venda original a partir de uma nota de devolução
> SELECT original.chave_acesso AS chave_nota_original,
>        devolucao.chave_acesso AS chave_nota_devolucao
> FROM nfe AS devolucao
> JOIN nfe AS original ON original.id_nfe = devolucao.id_nfe_referenciada
> WHERE devolucao.id_nfe = @id_nfe_devolucao;
> ```
> Note o uso de **dois apelidos (`alias`) diferentes para a mesma tabela** (`devolucao` e `original`) — essa é a técnica padrão de *self join*, necessária sempre que se consulta um autorrelacionamento.

---

## 10. Regra 7 — Relacionamento 1:1 → FK com UNIQUE

**Definição:** coloca-se a chave estrangeira em um dos lados do relacionamento, complementada por uma constraint `UNIQUE`, garantindo que cada ocorrência de um lado se associe a, no máximo, uma ocorrência do outro.

### Exemplo detalhado: Registro 0000 (Abertura) do arquivo EFD

Todo arquivo de EFD (SPED Fiscal) começa **obrigatoriamente** com um **Registro 0000**, que identifica o arquivo digital: período de apuração, contribuinte, perfil de apresentação, etc. Cada arquivo EFD tem **exatamente um** registro 0000 — nunca mais de um, nunca zero.

```
Arquivo EFD (1) ── possui ── (1) Registro 0000 (Abertura do Arquivo)
```

**Aplicando a Regra 7:**

```sql
CREATE TABLE efd_arquivo (
    id_arquivo_efd     BIGINT IDENTITY(1,1) NOT NULL,
    id_contribuinte      BIGINT       NOT NULL,
    periodo_apuracao       CHAR(7)      NOT NULL,
    data_recepcao             DATETIME2    NOT NULL,
    CONSTRAINT pk_efd_arquivo PRIMARY KEY (id_arquivo_efd),
    CONSTRAINT fk_efdarquivo_contribuinte FOREIGN KEY (id_contribuinte)
        REFERENCES contribuinte (id_contribuinte)
);
GO

CREATE TABLE efd_registro_0000 (
    id_registro_0000    BIGINT IDENTITY(1,1) NOT NULL,
    id_arquivo_efd        BIGINT        NOT NULL,
    codigo_versao_layout    VARCHAR(10)   NOT NULL,
    finalidade_arquivo        VARCHAR(20)   NOT NULL,
    CONSTRAINT pk_efd_registro_0000 PRIMARY KEY (id_registro_0000),
    -- o UNIQUE é o que efetivamente garante a cardinalidade "1:1":
    CONSTRAINT uq_efd_0000_por_arquivo UNIQUE (id_arquivo_efd),
    CONSTRAINT fk_0000_arquivo FOREIGN KEY (id_arquivo_efd)
        REFERENCES efd_arquivo (id_arquivo_efd)
);
```

> **O detalhe que faz a diferença entre 1:N e 1:1:** sem a constraint `UNIQUE (id_arquivo_efd)`, a `FOREIGN KEY` sozinha permitiria **vários** registros `0000` para o mesmo `id_arquivo_efd` — ou seja, o esquema representaria, na verdade, um relacionamento **1:N**, não **1:1**. É exatamente o `UNIQUE` sobre a coluna de FK que transforma "muitos possíveis" em "no máximo um". **Esse é o erro de modelagem mais comum ao implementar relacionamentos 1:1 — esquecer o `UNIQUE` e, sem perceber, modelar um 1:N.**

> **Outro exemplo do mesmo padrão:** o **Registro 9999** (Encerramento do Arquivo Digital) tem a mesma relação 1:1 com `efd_arquivo`, e seria implementado de forma idêntica.

---

## 11. Consolidando: Modelo Conceitual Único (EFD + NF-e)

Reunindo todos os exemplos das sete regras em um único diagrama conceitual:

```
Contribuinte (1) ──emite──> (N) Nota Fiscal Eletrônica (NF-e)  [Regra 3]
                                        │
                    ┌───────────────────┼─────────────────────────┐
                    │                   │                          │
              (1) referencia       (1)──possui──>(N)          (1)──possui──>(N)
                    │  [Regra 6]      Duplicata NF-e            Evento NF-e
                    ▼                  [Regra 2 / 5]              [Regra 5]
        Nota Fiscal Eletrônica
           (autorrelac.)

CT-e (N) ──transporta── (N) Nota Fiscal Eletrônica   [Regra 4: tabela associativa cte_nfe_transportada]

Contribuinte (1) ──envia──> (N) Arquivo EFD ──possui──> (1) Registro 0000  [Regra 7]
                                        │
                                        └──possui──> (N) Registro C100 ──possui──> (N) Registro C170  [Regra 3]
```

Esquema relacional resultante (notação resumida):

```
contribuinte(id_contribuinte, cnpj_cpf, razao_social, uf)

nfe(id_nfe, chave_acesso, numero_nf, serie, data_emissao, valor_total, situacao,
    id_contribuinte_emitente FK, id_nfe_referenciada FK [autorrelac.])

duplicata_nfe(id_duplicata, id_nfe FK, numero_duplicata, data_vencimento, valor_duplicata)
    UNIQUE(id_nfe, numero_duplicata)

evento_nfe(id_evento, id_nfe FK, numero_sequencial_evento, tipo_evento, data_hora_evento)
    UNIQUE(id_nfe, numero_sequencial_evento)

cte(id_cte, chave_acesso, id_contribuinte_emitente FK, valor_frete)

cte_nfe_transportada(id_cte FK, id_nfe FK, valor_mercadoria_transportada)
    PK(id_cte, id_nfe)

efd_arquivo(id_arquivo_efd, id_contribuinte FK, periodo_apuracao, data_recepcao)

efd_registro_0000(id_registro_0000, id_arquivo_efd FK, codigo_versao_layout, finalidade_arquivo)
    UNIQUE(id_arquivo_efd)

efd_registro_c100(id_c100, id_contribuinte FK, chave_acesso_nfe, periodo_apuracao, valor_total_documento)

efd_registro_c170(id_c170, id_c100 FK, numero_item, codigo_produto, cfop, valor_item)
```

---

## 12. Roteiro Prático — Script T-SQL Completo

**Objetivo:** implementar, no SSMS, o esquema relacional integrado da seção 11, aplicando todas as regras de mapeamento estudadas em sequência.

1. Abra uma nova *Query* no SSMS sobre o banco `curso_integridade_fiscal`.
2. Execute o script abaixo bloco a bloco. Para cada `CREATE TABLE` (ou `ALTER TABLE`), identifique em voz alta, com a turma, **qual das 7 regras** está sendo aplicada.

```sql
USE curso_integridade_fiscal;
GO

-- (Pressupõe que 'contribuinte' e 'nfe' já existem, criadas em módulos anteriores.
--  Caso este módulo seja aplicado de forma isolada, crie-as com base na Regra 1 — seção 4.)

-- REGRA 6 — Autorrelacionamento: NF-e referencia outra NF-e
ALTER TABLE nfe
ADD id_nfe_referenciada BIGINT NULL;
GO

ALTER TABLE nfe
ADD CONSTRAINT fk_nfe_referenciada
    FOREIGN KEY (id_nfe_referenciada) REFERENCES nfe (id_nfe);
GO

-- REGRA 2 / 5 — Atributo multivalorado modelado como entidade fraca: Duplicata da NF-e
CREATE TABLE duplicata_nfe (
    id_duplicata       BIGINT IDENTITY(1,1) NOT NULL,
    id_nfe               BIGINT         NOT NULL,
    numero_duplicata       VARCHAR(10)    NOT NULL,
    data_vencimento          DATE           NOT NULL,
    valor_duplicata            NUMERIC(15,2)  NOT NULL,
    CONSTRAINT pk_duplicata_nfe PRIMARY KEY (id_duplicata),
    CONSTRAINT uq_duplicata_por_nfe UNIQUE (id_nfe, numero_duplicata),
    CONSTRAINT ck_duplicata_valor_positivo CHECK (valor_duplicata >= 0),
    CONSTRAINT fk_duplicata_nfe FOREIGN KEY (id_nfe)
        REFERENCES nfe (id_nfe) ON DELETE CASCADE
);
GO

-- REGRA 5 — Entidade fraca: Evento da NF-e
CREATE TABLE evento_nfe (
    id_evento                  BIGINT IDENTITY(1,1) NOT NULL,
    id_nfe                       BIGINT       NOT NULL,
    numero_sequencial_evento       INT          NOT NULL,
    tipo_evento                      VARCHAR(30)  NOT NULL,
    data_hora_evento                   DATETIME2    NOT NULL,
    descricao_evento                     VARCHAR(500) NULL,
    CONSTRAINT pk_evento_nfe PRIMARY KEY (id_evento),
    CONSTRAINT uq_evento_por_nfe UNIQUE (id_nfe, numero_sequencial_evento),
    CONSTRAINT ck_tipo_evento CHECK (tipo_evento IN ('CANCELAMENTO','CCE','MANIFESTACAO_DESTINATARIO')),
    CONSTRAINT fk_evento_nfe FOREIGN KEY (id_nfe)
        REFERENCES nfe (id_nfe) ON DELETE CASCADE
);
GO

-- REGRA 1 e 3 — Entidade forte (CT-e) + relacionamento 1:N com contribuinte
CREATE TABLE cte (
    id_cte                      BIGINT IDENTITY(1,1) NOT NULL,
    chave_acesso                  CHAR(44)       NOT NULL,
    id_contribuinte_emitente       BIGINT         NOT NULL,
    valor_frete                       NUMERIC(15,2)  NOT NULL,
    CONSTRAINT pk_cte PRIMARY KEY (id_cte),
    CONSTRAINT uq_cte_chave UNIQUE (chave_acesso),
    CONSTRAINT fk_cte_emitente FOREIGN KEY (id_contribuinte_emitente)
        REFERENCES contribuinte (id_contribuinte)
);
GO

-- REGRA 4 — Relacionamento N:N: CT-e transporta NF-e
CREATE TABLE cte_nfe_transportada (
    id_cte                          BIGINT         NOT NULL,
    id_nfe                            BIGINT         NOT NULL,
    valor_mercadoria_transportada       NUMERIC(15,2)  NOT NULL,
    CONSTRAINT pk_cte_nfe_transportada PRIMARY KEY (id_cte, id_nfe),
    CONSTRAINT ck_valor_transportado_positivo CHECK (valor_mercadoria_transportada >= 0),
    CONSTRAINT fk_ctenfe_cte FOREIGN KEY (id_cte) REFERENCES cte (id_cte),
    CONSTRAINT fk_ctenfe_nfe FOREIGN KEY (id_nfe) REFERENCES nfe (id_nfe)
);
GO

-- REGRA 1 e 3 — Arquivo EFD (entidade forte, 1:N com contribuinte)
CREATE TABLE efd_arquivo (
    id_arquivo_efd      BIGINT IDENTITY(1,1) NOT NULL,
    id_contribuinte        BIGINT       NOT NULL,
    periodo_apuracao          CHAR(7)      NOT NULL,
    data_recepcao               DATETIME2    NOT NULL,
    CONSTRAINT pk_efd_arquivo PRIMARY KEY (id_arquivo_efd),
    CONSTRAINT fk_efdarquivo_contribuinte FOREIGN KEY (id_contribuinte)
        REFERENCES contribuinte (id_contribuinte)
);
GO

-- REGRA 7 — Relacionamento 1:1: Arquivo EFD possui um único Registro 0000
CREATE TABLE efd_registro_0000 (
    id_registro_0000     BIGINT IDENTITY(1,1) NOT NULL,
    id_arquivo_efd          BIGINT        NOT NULL,
    codigo_versao_layout       VARCHAR(10)   NOT NULL,
    finalidade_arquivo            VARCHAR(20)   NOT NULL,
    CONSTRAINT pk_efd_registro_0000 PRIMARY KEY (id_registro_0000),
    CONSTRAINT uq_efd_0000_por_arquivo UNIQUE (id_arquivo_efd),
    CONSTRAINT fk_0000_arquivo FOREIGN KEY (id_arquivo_efd)
        REFERENCES efd_arquivo (id_arquivo_efd)
);
GO

-- REGRA 1 e 3 — Registro C100 (1:N com efd_arquivo) e Registro C170 (1:N com C100)
CREATE TABLE efd_registro_c100 (
    id_c100                BIGINT IDENTITY(1,1) NOT NULL,
    id_arquivo_efd            BIGINT         NOT NULL,
    chave_acesso_nfe             CHAR(44)       NOT NULL,
    valor_total_documento           NUMERIC(15,2)  NOT NULL,
    CONSTRAINT pk_efd_c100 PRIMARY KEY (id_c100),
    CONSTRAINT fk_c100_arquivo FOREIGN KEY (id_arquivo_efd)
        REFERENCES efd_arquivo (id_arquivo_efd)
);
GO

CREATE TABLE efd_registro_c170 (
    id_c170            BIGINT IDENTITY(1,1) NOT NULL,
    id_c100               BIGINT         NOT NULL,
    numero_item             INT            NOT NULL,
    codigo_produto             VARCHAR(60)    NOT NULL,
    cfop                          CHAR(4)        NOT NULL,
    valor_item                       NUMERIC(15,2)  NOT NULL,
    CONSTRAINT pk_efd_c170 PRIMARY KEY (id_c170),
    CONSTRAINT ck_c170_valor_positivo CHECK (valor_item >= 0),
    CONSTRAINT fk_c170_c100 FOREIGN KEY (id_c100)
        REFERENCES efd_registro_c100 (id_c100) ON DELETE CASCADE
);
GO
```

3. Use o **Object Explorer** → **Database Diagrams** → **New Database Diagram** para montar visualmente o esquema completo e comparar com o diagrama da seção 11.

---

## 13. Exercícios Práticos

### Exercício 1 — Identificando a regra correta (teórico)
Para cada situação abaixo, identifique **qual das sete regras de mapeamento** se aplica e justifique:

a) Uma NFC-e possui vários "meios de pagamento" informados (dinheiro, cartão de débito, cartão de crédito, PIX), cada um com seu valor.
b) Um contribuinte pode ter, ao longo do tempo, vários "domicílios tributários eletrônicos" cadastrados, mas apenas um vigente por vez.
c) Um Registro C190 (Registro Analítico do CFOP) da EFD pertence a exatamente um Registro C100.
d) Uma NF-e complementar referencia a NF-e original que está sendo complementada.
e) Um mesmo veículo de carga (placa) pode estar associado a vários CT-e ao longo do tempo, e um CT-e pode envolver mais de um veículo (em caso de baldeação).

### Exercício 2 — Meios de pagamento da NFC-e (Regra 2)
O layout da NFC-e prevê o grupo **`pag`**, que pode ter **mais de uma ocorrência** por documento (ex.: parte do pagamento em dinheiro, parte em cartão).
a) Modele esse atributo multivalorado como uma nova tabela `pagamento_nfce`, aplicando a Regra 2.
b) Adicione as constraints necessárias para impedir valores de pagamento negativos.
c) Escreva uma consulta que retorne o valor total pago em `PIX` por período de apuração.

### Exercício 3 — CT-e e o autorrelacionamento de substituição
Assim como a NF-e pode referenciar outra NF-e (Regra 6), um **CT-e de substituição** pode referenciar o **CT-e original** que está sendo substituído (por erro de emissão, por exemplo).
a) Aplique a Regra 6 à tabela `cte`, adicionando a coluna e a constraint necessárias.
b) Escreva uma consulta (*self join*) que retorne a chave de acesso do CT-e original ao lado da chave de acesso do CT-e substituto.

### Exercício 4 — Revisitando a tabela associativa
Usando `cte_nfe_transportada` (Regra 4):
a) Insira um CT-e que transporte 2 NF-e diferentes.
b) Tente inserir a mesma combinação `(id_cte, id_nfe)` duas vezes. O que acontece, e por quê (relacione com a `PRIMARY KEY` composta)?
c) Escreva uma consulta que retorne, para cada NF-e, quantos CT-e diferentes a transportaram — um indício de possível fracionamento irregular de carga se o número for muito alto.

### Exercício 5 — Corrigindo um erro de modelagem 1:1
Um colega implementou a relação entre `efd_arquivo` e `efd_registro_0000` (Regra 7) **sem** a constraint `UNIQUE (id_arquivo_efd)`.
a) Explique, em termos práticos, o que passa a ser permitido nessa tabela que não deveria ser.
b) Escreva o comando `ALTER TABLE` que adiciona a constraint `UNIQUE` faltante a uma tabela já criada.
c) Se já existissem dados duplicados na tabela antes da correção, o que aconteceria ao tentar essa alteração?

### Exercício 6 (Desafio) — Registro C190 como novo nível hierárquico
A EFD também possui o **Registro C190** (Registro Analítico do CFOP), que também é filho do Registro C100 (assim como o C170), mas resume os valores **por CFOP e alíquota de ICMS**, e não por item individual.
a) Modele `efd_registro_c190`, aplicando a Regra 3 corretamente (qual é o lado "1" e qual é o lado "N"?).
b) Discuta: `efd_registro_c190` deveria ter alguma relação direta com `efd_registro_c170`, ou os dois são "irmãos" (ambos filhos de C100, sem relação direta entre si)? Justifique com base no MER da EFD.

---

## 14. Glossário

| Termo | Definição |
|---|---|
| **Autorrelacionamento** | Relacionamento em que uma entidade se associa a ocorrências dela mesma |
| **Tabela associativa** | Tabela criada para representar um relacionamento N:N, com chave composta pelas FKs das entidades envolvidas |
| **Entidade fraca** | Entidade cuja existência depende de outra; seu identificador só é único dentro do contexto da entidade da qual depende |
| **Atributo multivalorado** | Atributo que pode assumir mais de um valor para a mesma ocorrência de entidade |
| **Self join** | Técnica de `JOIN` de uma tabela consigo mesma, usando apelidos (`alias`) diferentes, típica de consultas sobre autorrelacionamentos |
| **NFref** | Grupo do layout da NF-e usado para referenciar outro documento fiscal (ex.: nota original em uma devolução) |
| **nSeqEvento** | Campo do Ambiente Nacional da NF-e que numera sequencialmente os eventos (cancelamento, CC-e etc.) de uma mesma NF-e |
| **Bloco C (EFD)** | Bloco da EFD ICMS/IPI dedicado aos documentos fiscais, com hierarquia de registros (C100, C170, C190, entre outros) |

---

## 15. Referências

- ELMASRI, R.; NAVATHE, S. *Sistemas de Banco de Dados*. 7ª ed. Pearson. (Capítulo de Mapeamento ER para Relacional)
- HEUSER, C. A. *Projeto de Banco de Dados*. 6ª ed. Bookman.
- Manual de Orientação do Contribuinte — NF-e (grupos `NFref`, `cobr`/`dup`, eventos): https://www.nfe.fazenda.gov.br
- Manual de Orientação do Contribuinte — NFC-e (grupo `pag`): https://www.nfce.fazenda.gov.br
- Manual de Orientação do Contribuinte — CT-e: https://www.cte.fazenda.gov.br
- Guia Prático da EFD ICMS/IPI (estrutura de blocos e registros): http://sped.rfb.gov.br
- Documentação oficial da Microsoft — "CREATE TABLE (Transact-SQL)": https://learn.microsoft.com/sql/t-sql/statements/create-table-transact-sql

---

*Material elaborado para uso interno no curso de Banco de Dados Relacionais — Módulo Regras de Mapeamento MER → Modelo Relacional — SEFAZ-PB.*