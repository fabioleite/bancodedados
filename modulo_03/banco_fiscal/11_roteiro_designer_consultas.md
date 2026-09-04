# Roteiro Pratico - Designer de Consultas (Query Designer) - Fiscalizacao Tributaria

**Banco:** `curso_integridade_fiscal`
**SGBD:** Microsoft SQL Server (T-SQL)
**Ferramenta:** Designer de Consultas do SSMS (`Ctrl+Shift+Q`), conforme a secao 5 da apostila `apostila_ferramentas_graficas_sql.md`

## Preparacao

Execute, nesta ordem, os scripts `01_criar_banco.sql` a `05_inserir_fiscalizacao.sql`. O exercicio 3 usa `ordem_servico` e `auto_infracao` (script 05); os demais usam apenas os scripts 01 a 04.

## Regras dos quatro exercicios

- Monte cada consulta pelo Designer (`Consulta > Design Query in Editor...` ou `Ctrl+Shift+Q`); nao digite o SQL direto no editor.
- Use apenas `INNER JOIN` - nao marque "Selecionar Todas as Linhas" de nenhuma tabela.
- Nao use `GROUP BY`/agregacao (`Soma`, `Contagem` etc. na coluna "Agrupar por") e nao use subconsultas. Se o Designer sugerir uma subconsulta ao arrastar algo, desfaca e resolva com juncao.
- Toda consulta precisa de pelo menos um filtro (coluna "Onde") e uma ordenacao.
- Confira sempre o painel SQL antes de executar - e ali que se percebe se uma juncao saiu `LEFT` por engano ou se um filtro sobre a tabela do lado direito foi parar no `WHERE` quando deveria estar no `ON`.
- **Nota sobre CEST.** A base `curso_integridade_fiscal` nao possui a coluna CEST - ela nao faz parte do schema deste banco. O exercicio 4 usa `cst_icms` (Codigo de Situacao Tributaria do ICMS), que cumpre papel equivalente de classificar a tributacao do item, mantendo NCM e CFOP conforme pedido.

---

## Exercicio 1 - Conferencia item a item: NF-e x EFD (C100/C170)

**Cenario.** Chegou indicio de que um contribuinte pode estar alterando a classificacao fiscal (NCM) ou o CFOP do item entre o que foi emitido na NF-e e o que foi de fato escriturado na EFD - pratica que pode mascarar reducao indevida de aliquota. Antes de qualquer conclusao, e preciso montar a listagem detalhada, item a item, para leitura manual do auditor. Nao cabe agregacao aqui: o interesse e comparar linha a linha.

**Tabelas:** `nfe`, `nfe_item`, `efd_c100`, `efd_c170`.

**Passos:**

1. Adicione as quatro tabelas ao Designer.
2. A juncao `nfe -> nfe_item` (por `id_nfe`) e a juncao `efd_c100 -> efd_c170` (por `id_c100`) aparecem sozinhas, porque tem FK declarada.
3. A juncao entre `nfe` e `efd_c100` **nao** aparece automaticamente - nao existe FK entre `chave_acesso` das duas tabelas (a base foi montada assim de proposito, para permitir documentos de outras UFs na EFD). Arraste `chave_acesso` de `nfe` sobre `chave_acesso` de `efd_c100` para criar a juncao manualmente. Confira no painel SQL que ficou `INNER JOIN`.
4. Falta ligar o item da NF-e ao item da EFD: arraste tambem `num_item` de `nfe_item` sobre `num_item` de `efd_c170`, criando uma segunda condicao de juncao entre essas duas tabelas (as duas condicoes se somam com `AND`). Sem isso, o Designer cruza todos os itens de um documento com todos os itens do outro documento.
5. Marque as colunas: de `nfe` - `chave_acesso`, `data_emissao`; de `nfe_item` - `num_item`, `ncm` (alias `ncm_nfe`), `cfop` (alias `cfop_nfe`), `valor_total_item` (alias `valor_nfe`); de `efd_c170` - `ncm` (alias `ncm_efd`), `cfop` (alias `cfop_efd`), `valor_item` (alias `valor_efd`).
6. Filtros (coluna "Onde"): `nfe.situacao = 'AUTORIZADA'`; `nfe.tipo_operacao = '1'`; `efd_c100.ind_oper = '1'`; `efd_c100.cod_situacao = '00'`; `efd_c100.periodo_apuracao = ` escolha um periodo valido, por exemplo `'202502'`.
7. Ordenacao: por `chave_acesso` e, dentro dela, por `num_item`, ambos crescentes.
8. Execute e leia as linhas em que `ncm_nfe`/`cfop_nfe` diverge da coluna `_efd` correspondente, ou em que `valor_nfe` e `valor_efd` nao batem. Como a consulta nao usa agregacao, espere uma minoria de linhas divergentes no meio de muitas conciliadas - e assim mesmo, no mundo real, que esse tipo de malha aparece.
9. Desafio opcional (sem resposta pronta): acrescente uma coluna do tipo "Expressao" que calcule `valor_nfe - valor_efd`, para tambem poder ordenar por essa diferenca.

---

## Exercicio 2 - Pauta fiscal (referencia_preco) x itens de NF-e: priorizacao por proximidade ao teto

**Cenario.** A pauta fiscal de referencia (`referencia_preco`) guarda, por NCM, a faixa de valor unitario esperada. Antes de apontar qualquer irregularidade, a equipe de monitoramento quer **ranquear** os itens de saida cujo valor unitario praticado esta mais proximo do teto da faixa (`valor_max`), dentro de um segmento de interesse - sinal de operacoes que merecem acompanhamento antes de eventualmente ultrapassarem a pauta. E um cruzamento por juncao teta (comparacao de faixa, nao de igualdade), sem qualquer agregacao.

**Tabelas:** `nfe`, `nfe_item`, `referencia_preco`.

**Passos:**

1. Adicione as tres tabelas. A juncao `nfe -> nfe_item` aparece sozinha.
2. A juncao entre `nfe_item` e `referencia_preco` **nao** aparece automaticamente - nao ha FK declarada entre `nfe_item.ncm` e `referencia_preco.ncm` (o proprio `LEIA-ME` do banco descreve essa tabela como "usada no exemplo de juncao teta"). Arraste `ncm` de `nfe_item` sobre `ncm` de `referencia_preco` para criar a juncao manualmente.
3. Marque as colunas: de `nfe` - `numero`, `data_emissao`; de `nfe_item` - `descricao`, `ncm`, `valor_unitario`; de `referencia_preco` - `descricao` (alias `descricao_pauta`), `valor_min`, `valor_max`.
4. Acrescente uma coluna do tipo "Expressao" (nao e agregacao, e um calculo por linha): `valor_max - valor_unitario`, com alias `distancia_teto`.
5. Filtros: `nfe.tipo_operacao = '1'`; `nfe.situacao = 'AUTORIZADA'`; restrinja a um segmento, por exemplo `nfe_item.ncm LIKE '22%'` (capitulo 22 da NCM = bebidas) - troque o prefixo para auditar outro segmento.
6. Ordenacao: por `distancia_teto`, crescente (os itens mais proximos do teto aparecem primeiro).
7. Confira no painel SQL: apenas os dois `INNER JOIN`, sem `GROUP BY` e sem subconsulta.

> **Atencao ao resultado.** Se, como variacao, voce tentar um filtro de violacao estrita (`valor_unitario < valor_min OR valor_unitario > valor_max`), nao estranhe se vier vazio: esta pauta foi construida com margem de 15% para mais e para menos sobre o preco realmente praticado na base, exatamente para reduzir falso positivo. Um resultado vazio nesse teste e, ele mesmo, uma conclusao valida de auditoria - a pauta esta bem calibrada -, nao um sinal de erro na sua consulta.

---

## Exercicio 3 - Cobranca em aberto: auto de infracao x ordem de servico x contribuinte

**Cenario.** A chefia pediu uma lista de acompanhamento dos autos de infracao **ainda nao pagos**, lavrados a partir de ordens de servico do tipo `MALHA FISCAL`, para priorizar os contribuintes com maior valor em aberto.

**Tabelas:** `auto_infracao`, `ordem_servico`, `contribuinte`.

**Passos:**

1. Adicione as tres tabelas. As duas juncoes (`auto_infracao -> ordem_servico` por `id_os`, `auto_infracao -> contribuinte` por `id_contribuinte`) aparecem sozinhas - ambas tem FK declarada.
2. Marque as colunas: de `auto_infracao` - `numero_auto`, `data_lavratura`, `dispositivo_legal`, `situacao`, `valor_principal`, `valor_multa`; de `ordem_servico` - `numero_os`, `tipo_fiscalizacao`; de `contribuinte` - `cnpj`, `razao_social`, `situacao_cadastral`.
3. Acrescente uma coluna "Expressao" `valor_principal + valor_multa`, alias `valor_total_exigencia` (soma linha a linha, nao e agregacao).
4. Filtros: `ordem_servico.tipo_fiscalizacao = 'MALHA FISCAL'`; `auto_infracao.situacao <> 'PAGO'` (ou, se preferir, use `IN` com a lista dos status em aberto: `LAVRADO`, `IMPUGNADO`, `JULGADO PROCEDENTE`, `INSCRITO DIVIDA ATIVA`).
5. Ordenacao: por `valor_total_exigencia`, decrescente.
6. Confira no painel SQL: dois `INNER JOIN`, nenhum `GROUP BY`/`HAVING`, nenhuma subconsulta.
7. Desafio opcional: repita a consulta filtrando tambem `contribuinte.situacao_cadastral = 'SUSPENSO'`, para o recorte mais estrito que a chefia tambem pediu.

---

## Exercicio 4 - Barreira fiscal: mercadoria sensivel em operacao interestadual (NCM x CFOP x CST)

**Cenario.** A fiscalizacao volante recebeu ordem de servico do tipo `DILIGENCIA` para montar, antes de uma acao num posto de fronteira, a lista de itens de um segmento sensivel (por exemplo, bebidas) remetidos para fora do estado, com a respectiva classificacao tributaria, para conferencia fisica da carga contra o documento fiscal que a acompanha.

**Tabelas:** `nfe`, `nfe_item`, `contribuinte`.

**Passos:**

1. Adicione as tres tabelas. As duas juncoes (`nfe -> nfe_item` por `id_nfe`, `nfe -> contribuinte` por `id_emitente`) aparecem sozinhas - ambas tem FK declarada.
2. Marque as colunas: de `nfe` - `chave_acesso`, `numero`, `data_emissao`; de `nfe_item` - `descricao`, `ncm`, `cfop`, `cst_icms`, `quantidade`, `valor_total_item`; de `contribuinte` - `razao_social`, `regime_tributario`, `situacao_cadastral`.
3. Filtros: `nfe.tipo_operacao = '1'`; `nfe.situacao = 'AUTORIZADA'`; `nfe_item.ncm LIKE '22%'` (bebidas - troque para `'2710%'` se quiser combustiveis); `nfe_item.cfop LIKE '6%'` (operacao para fora do estado); `contribuinte.situacao_cadastral = 'ATIVO'`.
4. Ordenacao: por `data_emissao`, decrescente, e depois por `valor_total_item`, decrescente.
5. Confira no painel SQL: dois `INNER JOIN`, nenhum `GROUP BY` e nenhuma subconsulta.
6. Desafio opcional: troque `LIKE '6%'` por `LIKE '5%'` (dentro do estado) e compare o volume de itens do mesmo segmento - a diferenca ajuda a dimensionar o peso das operacoes interestaduais nesse segmento.

---

## Entrega

Para cada exercicio, monte a consulta pelo Designer, confira o SQL no painel, execute e depois copie o SQL final para um unico arquivo `.sql`, separando cada um com um comentario `-- Exercicio 1`, `-- Exercicio 2` e assim por diante. Junto de cada consulta, escreva um paragrafo curto (2 a 4 linhas) descrevendo o que foi encontrado - lembrando que o resultado de uma consulta de malha e sempre **indicio**, nunca conclusao por si so (secao 15 da apostila).
