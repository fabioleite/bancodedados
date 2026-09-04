# Gabarito - Designer de Consultas (Query Designer) - Fiscalizacao Tributaria

Este gabarito acompanha o `11_roteiro_designer_consultas.md`. Traz, para cada exercicio, a consulta completa (equivalente ao que o Designer gera depois de seguir os passos do roteiro) e os numeros esperados na base `curso_integridade_fiscal`, para o aluno conferir o proprio resultado.

**Como os numeros foram obtidos.** Os dados desta base sao gerados por `gerar_dados.py` com semente fixa (`20260728`) - rodar o gerador de novo produz exatamente o mesmo banco. Os totais abaixo foram calculados reproduzindo a mesma logica de juncao/filtro diretamente sobre as estruturas geradas pelo script, e conferidos contra o conteudo real de `02_inserir_cadastros.sql` e `03_inserir_nfe.sql`. Se a sua base foi regenerada com outra semente ou volume (secao 6 do `00_LEIA-ME.md`), os totais mudam; o formato da consulta, nao.

**Dica de conferencia sem violar a regra do roteiro.** As consultas abaixo nao usam `GROUP BY` nem subconsulta, como pedido no roteiro. Para conferir a quantidade de linhas, rode uma **segunda consulta separada**, com a mesma clausula `FROM`/`JOIN`/`WHERE` mas trocando a lista do `SELECT` por `COUNT(*)` e removendo o `ORDER BY` - isso nao e uma subconsulta, e apenas outra consulta no mesmo editor.

---

## Exercicio 1 - Conferencia item a item: NF-e x EFD (C100/C170)

```sql
SELECT n.chave_acesso,
       n.data_emissao,
       i.num_item,
       i.ncm              AS ncm_nfe,
       c170.ncm           AS ncm_efd,
       i.cfop             AS cfop_nfe,
       c170.cfop          AS cfop_efd,
       i.valor_total_item AS valor_nfe,
       c170.valor_item    AS valor_efd
FROM   dbo.nfe AS n
       INNER JOIN dbo.nfe_item AS i
               ON i.id_nfe = n.id_nfe
       INNER JOIN dbo.efd_c100 AS e
               ON e.chave_acesso = n.chave_acesso
       INNER JOIN dbo.efd_c170 AS c170
               ON c170.id_c100  = e.id_c100
              AND c170.num_item = i.num_item
WHERE  n.situacao         = 'AUTORIZADA'
  AND  n.tipo_operacao    = '1'
  AND  e.ind_oper         = '1'
  AND  e.cod_situacao     = '00'
  AND  e.periodo_apuracao = '202502'
ORDER BY n.chave_acesso, i.num_item;
```

**Versao com o desafio opcional resolvido** (coluna calculada para facilitar a leitura, sem agregacao):

```sql
SELECT n.chave_acesso,
       n.data_emissao,
       i.num_item,
       i.ncm              AS ncm_nfe,
       c170.ncm           AS ncm_efd,
       i.cfop             AS cfop_nfe,
       c170.cfop          AS cfop_efd,
       i.valor_total_item AS valor_nfe,
       c170.valor_item    AS valor_efd,
       i.valor_total_item - c170.valor_item AS diferenca_valor,
       CASE WHEN i.ncm <> c170.ncm
              OR i.cfop <> c170.cfop
              OR ABS(i.valor_total_item - c170.valor_item) > 0.01
            THEN 'DIVERGENTE' ELSE 'CONCILIADA' END AS resultado
FROM   dbo.nfe AS n
       INNER JOIN dbo.nfe_item AS i
               ON i.id_nfe = n.id_nfe
       INNER JOIN dbo.efd_c100 AS e
               ON e.chave_acesso = n.chave_acesso
       INNER JOIN dbo.efd_c170 AS c170
               ON c170.id_c100  = e.id_c100
              AND c170.num_item = i.num_item
WHERE  n.situacao         = 'AUTORIZADA'
  AND  n.tipo_operacao    = '1'
  AND  e.ind_oper         = '1'
  AND  e.cod_situacao     = '00'
  AND  e.periodo_apuracao = '202502'
ORDER BY resultado DESC, n.chave_acesso, i.num_item;
```

### Validacao quantitativa (periodo 202502)

| Metrica | Valor esperado |
|---|---:|
| Total de linhas retornadas (universo conciliado) | **1.712** |
| Linhas marcadas `DIVERGENTE` (NCM, CFOP ou valor) | **21** |
| Linhas marcadas `CONCILIADA` | 1.691 |

Se voce escolher outro periodo em `e.periodo_apuracao`, o total muda - o importante e que a proporcao de divergentes fique numa faixa pequena (na base toda, ao redor de 1% a 2% dos itens escriturados divergem do que foi emitido).

Exemplos reais de linhas `DIVERGENTE` neste periodo (para conferir se a sua consulta encontra o mesmo tipo de caso):

| chave_acesso (final) | num_item | ncm_nfe | ncm_efd | cfop_nfe | cfop_efd | valor_nfe | valor_efd |
|---|---:|---|---|---|---|---:|---:|
| ...2291215848841 | 2 | 10063021 | 04022110 | 5102 | 5102 | 58,95 | 58,95 |
| ...0861469705635 | 2 | 10063021 | 10063021 | 5405 | 5405 | 559,26 | 398,85 |
| ...1751649419314 | 3 | 04022110 | 04022110 | 5102 | 5405 | 209,98 | 209,98 |
| ...1291084251375 | 1 | 21069029 | 21069029 | 6102 | 6102 | 676,95 | 437,46 |
| ...2111592653031 | 5 | 22084000 | 22084000 | 6102 | 5405 | 102,38 | 102,38 |

Repare que cada linha diverge por um motivo diferente (NCM trocado, CFOP trocado, ou so o valor) - e proposital: a EFD desta base tem quatro tipos de erro plantados no item (NCM, CFOP, aliquota ou valor), nunca mais de um por linha.

---

## Exercicio 2 - Pauta fiscal (referencia_preco) x itens de NF-e: priorizacao por proximidade ao teto

```sql
SELECT n.numero,
       n.data_emissao,
       i.descricao,
       i.ncm,
       i.valor_unitario,
       r.descricao                    AS descricao_pauta,
       r.valor_min,
       r.valor_max,
       r.valor_max - i.valor_unitario AS distancia_teto
FROM   dbo.nfe AS n
       INNER JOIN dbo.nfe_item AS i
               ON i.id_nfe = n.id_nfe
       INNER JOIN dbo.referencia_preco AS r
               ON r.ncm = i.ncm
WHERE  n.tipo_operacao = '1'
  AND  n.situacao      = 'AUTORIZADA'
  AND  i.ncm LIKE '22%'
ORDER BY distancia_teto ASC;
```

### Validacao quantitativa (segmento NCM `22%` - bebidas)

| Metrica | Valor esperado |
|---|---:|
| Total de linhas retornadas | **5.485** |
| Linhas com `valor_unitario < valor_min OU > valor_max` (violacao estrita) | **0** |

O total de zero violacoes confirma o aviso do roteiro: a pauta desta base tem margem de 15% para mais e para menos sobre o preco realmente praticado, entao nenhum item de saida autorizada extrapola a faixa. Se a sua consulta de violacao estrita devolver qualquer numero diferente de zero, revise o `JOIN` - o erro mais comum e ter deixado a juncao como `LEFT JOIN` (o Designer as vezes marca assim quando a linha e arrastada na direcao errada), o que traz `NULL` em `valor_min`/`valor_max` e faz a comparacao se comportar de forma inesperada.

5 itens mais proximos do teto da pauta (menor `distancia_teto` primeiro):

| numero | descricao | ncm | valor_unitario | valor_min | valor_max | distancia_teto |
|---:|---|---|---:|---:|---:|---:|
| 40 | AGUA MINERAL SEM GAS 500ML | 22011000 | 2,5977 | 0,7650 | 2,9900 | 0,3923 |
| 411 | AGUA MINERAL SEM GAS 500ML | 22011000 | 2,5960 | 0,7650 | 2,9900 | 0,3940 |
| 898 | AGUA MINERAL SEM GAS 500ML | 22011000 | 2,5950 | 0,7650 | 2,9900 | 0,3950 |
| 555 | AGUA MINERAL SEM GAS 500ML | 22011000 | 2,5946 | 0,7650 | 2,9900 | 0,3954 |
| 647 | AGUA MINERAL SEM GAS 500ML | 22011000 | 2,5946 | 0,7650 | 2,9900 | 0,3954 |

Nao e coincidencia todos serem do mesmo NCM: agua mineral e o item de menor faixa de preco absoluto do segmento de bebidas, entao pequenas variacoes de centavos ja o colocam perto do teto proporcionalmente.

---

## Exercicio 3 - Cobranca em aberto: auto de infracao x ordem de servico x contribuinte

```sql
SELECT a.numero_auto,
       a.data_lavratura,
       a.dispositivo_legal,
       a.situacao,
       a.valor_principal,
       a.valor_multa,
       a.valor_principal + a.valor_multa AS valor_total_exigencia,
       os.numero_os,
       os.tipo_fiscalizacao,
       c.cnpj,
       c.razao_social,
       c.situacao_cadastral
FROM   dbo.auto_infracao AS a
       INNER JOIN dbo.ordem_servico AS os
               ON os.id_os = a.id_os
       INNER JOIN dbo.contribuinte AS c
               ON c.id_contribuinte = a.id_contribuinte
WHERE  os.tipo_fiscalizacao = 'MALHA FISCAL'
  AND  a.situacao <> 'PAGO'
ORDER BY valor_total_exigencia DESC;
```

**Desafio opcional resolvido** (recorte adicional por `situacao_cadastral = 'SUSPENSO'`): basta acrescentar `AND c.situacao_cadastral = 'SUSPENSO'` ao `WHERE` acima.

### Validacao quantitativa

| Metrica | Valor esperado |
|---|---:|
| Total de autos MALHA FISCAL com situacao <> PAGO | **21** |
| ... dos quais SUSPENSO (desafio opcional) | conferir na sua execucao |

Distribuicao por `situacao` (soma 21):

| situacao | quantidade |
|---|---:|
| JULGADO PROCEDENTE | 6 |
| INSCRITO DIVIDA ATIVA | 6 |
| LAVRADO | 4 |
| JULGADO IMPROCEDENTE | 4 |
| IMPUGNADO | 1 |

5 maiores valores (`valor_total_exigencia` decrescente):

| numero_auto | data_lavratura | situacao | cnpj | razao_social | valor_total_exigencia |
|---|---|---|---|---|---:|
| AI-2025-00036 | 2026-03-07 | JULGADO PROCEDENTE | 33839864000150 | FAROL COMERCIO VAREJISTA DE CONFECCOES COMERCIO LTDA | 2.403.612,50 |
| AI-2025-00041 | 2026-03-27 | INSCRITO DIVIDA ATIVA | 68744764000125 | JUAZEIRO COMERCIO DE COMBUSTIVEIS EIRELI | 2.230.371,63 |
| AI-2025-00063 | 2026-04-05 | JULGADO PROCEDENTE | 23233085000153 | LUAR INDUSTRIA DE MOVEIS COMERCIO LTDA | 1.758.041,08 |
| AI-2025-00014 | 2026-02-21 | LAVRADO | 57032388000120 | VITORIA INDUSTRIA DE MOVEIS EIRELI | 1.732.982,33 |
| AI-2025-00001 | 2026-03-03 | INSCRITO DIVIDA ATIVA | 96510522000102 | ESPINHEIRO ATACADISTA DE MATERIAL DE CONSTRUCAO EIRELI | 506.369,80 |

Note o salto entre a 4a e a 5a linha (de R$ 1,73 milhao para R$ 506 mil) - as quatro maiores exigencias concentram a maior parte do valor em aberto desse recorte, um padrao tipico em cobranca administrativa que vale mencionar no paragrafo de achados.

---

## Exercicio 4 - Barreira fiscal: mercadoria sensivel em operacao interestadual (NCM x CFOP x CST)

```sql
SELECT n.chave_acesso,
       n.numero,
       n.data_emissao,
       i.descricao,
       i.ncm,
       i.cfop,
       i.cst_icms,
       i.quantidade,
       i.valor_total_item,
       c.razao_social,
       c.regime_tributario,
       c.situacao_cadastral
FROM   dbo.nfe AS n
       INNER JOIN dbo.nfe_item AS i
               ON i.id_nfe = n.id_nfe
       INNER JOIN dbo.contribuinte AS c
               ON c.id_contribuinte = n.id_emitente
WHERE  n.tipo_operacao      = '1'
  AND  n.situacao           = 'AUTORIZADA'
  AND  i.ncm  LIKE '22%'
  AND  i.cfop LIKE '6%'
  AND  c.situacao_cadastral = 'ATIVO'
ORDER BY n.data_emissao DESC, i.valor_total_item DESC;
```

### Validacao quantitativa (bebidas, fora do estado)

| Metrica | Valor esperado |
|---|---:|
| Total de linhas (`cfop LIKE '6%'`, fora do estado) | **888** |
| Total de linhas trocando para `cfop LIKE '5%'` (dentro do estado, desafio opcional) | **4.597** |

A proporcao interestadual/total fica perto de 16% neste segmento (888 de 5.485 itens de bebidas de saida autorizada, o mesmo universo do Exercicio 2) - numero util para comentar no paragrafo de achados.

5 primeiras linhas (`data_emissao` decrescente, depois `valor_total_item` decrescente):

| data_emissao | valor_total_item | numero | descricao | ncm | cfop | cst_icms | razao_social |
|---|---:|---:|---|---|---|---|---|
| 2025-12-30 | 801,91 | 668 | VINHO TINTO GARRAFA 750ML | 22042100 | 6102 | 000 | ALFA DISTRIBUIDORA DE BEBIDAS EIRELI |
| 2025-12-30 | 90,25 | 668 | CERVEJA DE MALTE LATA 350ML | 22030000 | 6102 | 000 | ALFA DISTRIBUIDORA DE BEBIDAS EIRELI |
| 2025-12-27 | 1.181,21 | 1339 | VINHO TINTO GARRAFA 750ML | 22042100 | 6102 | 000 | ALFA DISTRIBUIDORA DE BEBIDAS EIRELI |
| 2025-12-27 | 1.093,40 | 442 | VINHO TINTO GARRAFA 750ML | 22042100 | 6102 | 000 | ALFA DISTRIBUIDORA DE BEBIDAS EIRELI |
| 2025-12-27 | 528,05 | 1339 | AGUARDENTE DE CANA 1L | 22084000 | 6102 | 000 | ALFA DISTRIBUIDORA DE BEBIDAS EIRELI |

Todo `cst_icms` aparece como `000` (tributacao integral, regime NORMAL) nestas primeiras linhas porque a ALFA DISTRIBUIDORA e optante do regime NORMAL; se aparecer `101` na sua consulta, e um emitente do SIMPLES/MEI - vale conferir se o regime do emitente e compativel com a operacao interestadual de alto valor, ja que e um padrao que costuma chamar atencao na triagem de barreira.

---

## Observacao geral sobre os numeros

Todos os totais desta pagina foram conferidos diretamente contra o conteudo gerado pelo `gerar_dados.py` da propria pasta (semente fixa `20260728`), reproduzindo em Python a mesma logica de juncao e filtro de cada consulta - nao sao estimativas. Pequenas diferencas podem aparecer se a sua base foi recriada depois de uma alteracao no gerador (secao 6 do `00_LEIA-ME.md`); nesse caso, prefira validar pela **forma** da consulta (juncoes, filtros, ordenacao) e pela **ordem de grandeza** dos resultados, nao pelo numero exato.
