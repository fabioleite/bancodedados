# Gabarito — Ferramentas Gráficas para Análise com SQL

**Curso de Banco de Dados Relacional aplicado à Fiscalização Tributária — Módulo 10**
**Documento de uso do instrutor / correção**

> Vários exercícios dependem do conteúdo real da base do curso; nesses casos indica-se **o caminho** e **o que deve constar da resposta**, não um número fixo. Aceite qualquer solução equivalente que demonstre o raciocínio.

---

## Bloco A — Exploração pelo SSMS

**A1.** Caminho: *Pesquisador de Objetos ▸ Bancos de Dados ▸ curso_integridade_fiscal ▸ Tabelas* (nove tabelas no esquema do curso: `auditor_fiscal`, `auto_infracao`, `contribuinte`, `efd_c100`, `efd_c170`, `municipio`, `nfe`, `nfe_item`, `ordem_servico`). Para (b), expandir *nfe ▸ Colunas*: as colunas anuláveis aparecem com a indicação `null` ao lado do tipo — no esquema do curso, `id_destinatario`. Para (c), expandir *efd_c100 ▸ Índices*.
Resposta esperada deve mencionar que `id_destinatario` anulável é justamente o que torna perigoso o `NOT IN` (Módulo 9, A5) — a leitura da estrutura antecipa a armadilha.

**A2.** `F7` abre o painel de Detalhes; clicar no cabeçalho *Linhas* ordena. Espera-se `nfe_item` > `nfe` > `efd_c170`/`efd_c100`. Justificativa: o volume define a estratégia — em tabelas grandes é indispensável filtrar antes de juntar, evitar função sobre coluna filtrada e conferir o plano de execução; uma consulta que roda em segundos sobre `municipio` pode inviabilizar a sessão sobre `nfe_item`.

**A3.** *Botão direito sobre a tabela ▸ Script da Tabela como ▸ SELECT em ▸ Nova Janela do Editor*. O `CREATE TABLE` de `efd_c170` é evidência em auditoria de sistemas: documenta a estrutura vigente na data da diligência (colunas, tipos, restrições, chaves), permitindo demonstrar, por exemplo, que o sistema não impunha `NOT NULL` a um campo essencial, ou que não havia FK garantindo a integridade entre C100 e C170 — o que sustenta conclusões sobre a confiabilidade da escrituração.

**A4.** Espera-se a observação de pelo menos três dentre: razões sociais em caixa alta e sem acentuação; `nome_fantasia` com nulos; CNPJ armazenado como 14 dígitos sem máscara; datas no formato `AAAA-MM-DD`; `faturamento_declarado` com nulos; domínios de `situacao_cadastral` e `regime_tributario` em texto livre (risco de variação de grafia).

---

## Bloco B — Designer de Consultas

**B1.** Montagem: adicionar `contribuinte` e `municipio`; marcar `cnpj`, `razao_social` e `municipio.nome`; filtro `= 'ATIVO'` em `situacao_cadastral` e `= 'NORMAL'` em `regime_tributario`; *Tipo de Classificação* = Crescente em `razao_social`.

SQL gerado (típico):

```sql
SELECT        contribuinte.cnpj, contribuinte.razao_social, municipio.nome
FROM          contribuinte INNER JOIN
              municipio ON contribuinte.id_municipio = municipio.id_municipio
WHERE        (contribuinte.situacao_cadastral = 'ATIVO')
         AND (contribuinte.regime_tributario = 'NORMAL')
ORDER BY contribuinte.razao_social
```

Diferenças de estilo esperadas na resposta (duas quaisquer): não usa aliases de tabela, repetindo o nome inteiro; coloca o `INNER JOIN` no fim da linha e a tabela na linha seguinte; parenteses redundantes em cada condição do `WHERE`; identação por colunas fixas; não usa `AS` para alias de coluna; não qualifica o esquema (`dbo.`).

**B2.** Acionar o botão **Agrupar por (Σ)**. Em `id_contribuinte`/`cnpj`/`razao_social`, manter *Agrupar por*; em uma cópia de `id_nfe` usar *Contagem*; em `valor_total` usar *Soma*; filtro `> 100` na linha da contagem.

```sql
SELECT        contribuinte.cnpj, contribuinte.razao_social,
              COUNT(nfe.id_nfe) AS qtd_notas, SUM(nfe.valor_total) AS total_emitido
FROM          contribuinte INNER JOIN
              nfe ON contribuinte.id_contribuinte = nfe.id_emitente
WHERE        (nfe.situacao = 'AUTORIZADA')
GROUP BY contribuinte.cnpj, contribuinte.razao_social
HAVING        (COUNT(nfe.id_nfe) > 100)
```

Onde nasceu cada cláusula: o `GROUP BY` vem das linhas marcadas como *Agrupar por*; o `HAVING` vem do **filtro escrito em uma linha cuja coluna "Agrupar por" contém uma função agregada** (Contagem); o `WHERE` vem do filtro escrito em uma linha marcada como *Onde*. Essa é a tradução visual da distinção estudada no Módulo 9.

**B3.** Botão direito sobre a linha de junção ▸ **Selecionar Todas as Linhas de contribuinte**. O `INNER JOIN` passa a `LEFT OUTER JOIN`. Observação a cobrar: com a junção externa, `COUNT(nfe.id_nfe)` devolve 0 para quem não tem nota — enquanto `COUNT(*)` devolveria 1; se o aluno tiver usado `COUNT(*)`, o resultado estará errado.

**B4.** O Designer **não suporta** `EXCEPT` (nem `UNION` ou `INTERSECT`). Ao colar a consulta no painel SQL e tentar validá-la, o SSMS informa que a consulta não pode ser representada graficamente e, dependendo da versão, oferece continuar apenas no painel SQL — com os painéis de diagrama e critérios desabilitados. Razão: os painéis modelam **uma** expressão `SELECT` sobre um conjunto de tabelas com junções; operadores de conjunto combinam **duas ou mais** expressões independentes, para as quais não há representação em um único diagrama.

**B5.** O Designer aceita a consulta, mas a **reescreve**: perde os comentários, reformata a identação, reorganiza os parênteses e frequentemente converte a subconsulta `NOT EXISTS` para uma representação própria (ou recusa-se a exibir os painéis gráficos). Lição: o construtor gráfico é ferramenta de **montagem inicial e de leitura assistida**; a partir do momento em que a consulta incorpora subconsultas correlacionadas, CTEs, funções de janela ou operadores de conjunto, ela deve viver no editor de texto e ser versionada como código.

**B6.** O resultado **não** é o esperado: ao colocar `periodo_apuracao = '202501'` no `WHERE`, as linhas sem correspondência (que têm essa coluna nula) são descartadas e a junção externa se comporta como interna. Correção no painel SQL — mover a condição para o `ON`:

```sql
FROM   nfe LEFT OUTER JOIN
       efd_c100 ON efd_c100.chave_acesso = nfe.chave_acesso
                AND efd_c100.periodo_apuracao = '202501'
WHERE  nfe.situacao = 'AUTORIZADA'
   AND efd_c100.id_c100 IS NULL
```

Explicação a cobrar: no `ON`, a condição participa da **busca do par**; no `WHERE`, é aplicada ao resultado já montado, e `NULL = '202501'` é UNKNOWN.

---

## Bloco C — Exibições e diagramas

**C1.** *Exibições ▸ botão direito ▸ Nova Exibição…*; adicionar `auditor_fiscal`, `ordem_servico` e `auto_infracao`; junções externas a partir de `auditor_fiscal` para não perder quem não lavrou autos; agregações Contagem e Soma.

```sql
CREATE VIEW dbo.vw_autos_por_auditor AS
SELECT        af.matricula, af.nome, af.regiao_fiscal,
              COUNT(a.id_auto) AS qtd_autos,
              COALESCE(SUM(a.valor_principal + a.valor_multa), 0) AS valor_autuado
FROM          dbo.auditor_fiscal AS af LEFT OUTER JOIN
              dbo.ordem_servico  AS os ON os.matricula_auditor = af.matricula LEFT OUTER JOIN
              dbo.auto_infracao  AS a  ON a.id_os = os.id_os
GROUP BY af.matricula, af.nome, af.regiao_fiscal;
```

Consulta de verificação: `SELECT * FROM dbo.vw_autos_por_auditor ORDER BY valor_autuado DESC;`
Ponto de correção: uso de `LEFT JOIN` + `COUNT(a.id_auto)` + `COALESCE`, exatamente como no Módulo 9.

**C2.** O caminho é `nfe_item → nfe → efd_c100 → efd_c170`, pois não há ligação direta entre as tabelas de item; a correspondência entre documentos se dá pela `chave_acesso` e, entre itens, pelo `num_item`.

```sql
FROM   dbo.nfe_item AS i
       INNER JOIN dbo.nfe      AS n    ON n.id_nfe       = i.id_nfe
       INNER JOIN dbo.efd_c100 AS e    ON e.chave_acesso = n.chave_acesso
       INNER JOIN dbo.efd_c170 AS c170 ON c170.id_c100   = e.id_c100
                                      AND c170.num_item  = i.num_item
```

**C3.** Não existe — e não deveria existir — FK entre `efd_c100.chave_acesso` e `nfe.chave_acesso`. Duas razões: a coluna é anulável em `efd_c100` (documentos não eletrônicos) e, sobretudo, **a EFD pode escriturar documentos que não constam da base local de NF-e** (emitidos por contribuintes de outras UFs, ou simplesmente inexistentes). Consequência prática: o banco **não impede** escrituração de chave inválida — e é exatamente por isso que o cruzamento da seção 16 do Módulo 9 tem valor fiscal. Se houvesse FK, a inconsistência seria impossível e a consulta seria inútil.

---

## Bloco D — Planos de execução

**D1.** Espera-se: em `NOT EXISTS`, o otimizador produz tipicamente uma **semijunção anti** (Anti Semi Join) por Loops Aninhados ou Hash, com busca em índice na tabela interna; em `NOT IN` com proteção `IS NOT NULL`, o plano costuma ser semelhante, mas pode incluir um operador adicional de agregação/distinção da lista. O ponto didático central é que **planos semelhantes não significam consultas equivalentes**: sem o `IS NOT NULL`, a versão com `NOT IN` retorna vazio — erro de resultado, não de desempenho.

**D2.** Com `YEAR(data_emissao) = 2025`, a função aplicada à coluna impede o uso do índice: o plano mostra **Verificação (Scan)**. Com `data_emissao >= '2025-01-01' AND data_emissao < '2026-01-01'`, aparece **Busca (Seek)**. *Sargable* (de *Search ARGument ABLE*) é o predicado que o mecanismo consegue converter em operação de busca sobre índice: a coluna aparece isolada de um lado da comparação, sem função, conversão implícita ou cálculo. Exemplos de predicados não sargable no domínio fiscal: `YEAR(data)`, `LEFT(cnpj,8) = …`, `SUBSTRING(chave_acesso,7,14) = …`, `CAST(valor AS VARCHAR) LIKE …`.

**D3.** O parágrafo deve conter, no mínimo: (a) o índice sugerido e a consulta que o motivou; (b) o ganho esperado (transformar varredura de milhões de linhas em busca); (c) o custo: cada índice adicional onera `INSERT`/`UPDATE`/`DELETE` — relevante em tabela que recebe carga diária de documentos fiscais — e consome espaço, além de precisar ser mantido/estatísticas atualizadas; (d) a recomendação de testar em ambiente de homologação, medindo antes e depois, e de verificar se um índice já existente não pode ser estendido em vez de criado outro; (e) a observação de que a sugestão do otimizador considera **apenas aquela consulta**, e não a carga global do servidor.

---

## Bloco E — Excel, Power Query e Power BI

**E1.** SQL esperado (a forma exata varia com a versão):

```sql
select [_].[cnpj], [_].[razao_social], [_].[data_emissao], [_].[valor_total], [_].[valor_icms]
from [dbo].[vw_nfe_saidas] as [_]
where [_].[situacao] = 'AUTORIZADA' and [_].[data_emissao] >= '2025-01-01'
  and [_].[data_emissao] < '2025-02-01'
```

Ponto de correção: o aluno deve perceber que **o filtro feito por cliques virou cláusula `WHERE` executada no servidor** — não houve download da tabela inteira.

**E2.** Após *Adicionar Coluna de Índice*, a opção **Exibir Consulta Nativa** fica esmaecida naquela etapa e nas seguintes: a dobra foi quebrada. Consequência: o Power Query passa a trazer para a máquina do usuário o conjunto produzido até a última etapa dobrável e a executar localmente todo o restante. Em tabela com dezenas de milhões de linhas isso significa tráfego de rede maciço, consumo de memória do desktop, tempo de atualização inviável e — do ponto de vista de sigilo — replicação desnecessária de dado fiscal fora do servidor.

**E3.** *Página Inicial ▸ Gerenciar Parâmetros ▸ Novo Parâmetro* (`DataInicial`, `DataFinal`, tipo Data). Depois, na etapa de filtro, substituir o valor fixo pelo parâmetro (ou editar a etapa no Editor Avançado). Demonstração: alterar `DataInicial` para 01/02/2025 e `DataFinal` para 01/03/2025 e clicar em *Atualizar Tudo* — o mesmo arquivo passa a apurar fevereiro sem que uma linha de consulta seja tocada. Espera-se a observação de que isso converte a extração pontual em rotina mensal auditável.

**E4.** Sem definir o tipo como texto, o Power Query infere número inteiro e **os zeros à esquerda desaparecem** (`01234567000190` vira `1234567000190`); em alguns cenários a coluna vira notação científica. Correção: na etapa *Tipo Alterado*, definir `cnpj` como **Texto** (ou remover a etapa e refazer a tipagem). Risco fiscal: o cruzamento por CNPJ passa a não encontrar correspondência para todos os contribuintes cujo número começa por zero, e o relatório apresenta como "sem ocorrência" o que na verdade é falha de tipagem — falso negativo que pode arquivar indevidamente um indício, ou falso positivo que leva a intimar contribuinte regular.

**E5.** *Exibir ▸ Analisador de Desempenho ▸ Iniciar gravação ▸ Atualizar visuais ▸ Copiar consulta*. Em **DirectQuery**, o SQL copiado é enviado ao SQL Server e contém o `SELECT ... GROUP BY` correspondente ao visual, com `TOP (1000001)` — limite de segurança do Power BI. Em **Importação**, o Analisador exibe a consulta **DAX** contra o modelo em memória: não há SQL no momento da interação, porque os dados já estão dentro do `.pbix` (o SQL ocorreu apenas na atualização). Essa diferença é o ponto do exercício.

**E6.** A resposta deve articular: em **Importação**, o `.pbix` passa a conter cópia de dado protegido por sigilo fiscal, circula por e-mail/pen drive/OneDrive, permanece no equipamento após a conclusão do trabalho e não é revogável — se o servidor mudar de lotação, o arquivo continua com ele; exige criptografia, política de guarda e descarte. Em **DirectQuery**, nada é copiado: o controle de acesso permanece no banco, é possível aplicar RLS por região fiscal, e revogar a permissão elimina o acesso imediatamente; o registro de acesso continua no servidor. Recomendação esperada: **DirectQuery** para painel com CNPJ e valores individualizados, com RLS; Importação apenas para agregados que não identifiquem o contribuinte.

---

## Bloco F — Integração e julgamento profissional

**F1.** Percurso-modelo (aceitar variações justificadas), tomando a rotina de omissão de escrituração:

1. **Diagrama de BD** — confirmar o caminho `nfe → contribuinte` e a inexistência de FK com `efd_c100`, o que já indica a necessidade de cruzar por `chave_acesso`.
2. **Selecionar 1000 Linhas** em `efd_c100` — verificar preenchimento de `chave_acesso`, `cod_situacao` e `periodo_apuracao`.
3. **Designer de Consultas** — montar o esqueleto com as junções e o filtro de período.
4. **Editor de consultas** — substituir o esqueleto pelo `NOT EXISTS` e pela CTE de sumarização (o Designer não os comporta).
5. **Plano de execução** (`Ctrl+M`) — confirmar busca em índice; ajustar predicados se houver varredura.
6. **Exibição** — publicar como `vw_omissao_escrituracao_202501` para padronizar a definição.
7. **Entrega:** listagem individual para a OS via *Salvar Resultados como…*; acompanhamento gerencial via Power BI em DirectQuery sobre a exibição; conferência do total por contagem de controle independente.

**F2.** Cinco perguntas esperadas (aceitar equivalentes):

1. Qual o **SQL** efetivamente executado — a consulta nativa foi verificada, ou parte do processamento ocorreu no desktop sobre dado parcial?
2. Qual o **período** e qual o critério de "omisso": ausência de C100 do documento, ausência de entrega da EFD do período, ou ausência de registro de saída?
3. Foram excluídos os documentos **cancelados, denegados e inutilizados**, e os C100 com `cod_situacao` diferente de `00`?
4. O cruzamento usou `NOT IN` sobre coluna anulável (risco de resultado vazio ou distorcido) ou `NOT EXISTS`?
5. O CNPJ foi tratado como **texto**? Há contribuintes com zero à esquerda no resultado?
6. (bônus) A apuração é **reproduzível** — existe script, parâmetro de período e data/hora da extração?

**F3.** O procedimento deve contemplar, no mínimo:

- **Perfis de acesso**: somente leitura em produção; acesso a exibições em vez de tabelas de base; segregação por região fiscal quando aplicável; vedação a compartilhamento de credenciais.
- **Guarda de arquivos extraídos**: pasta institucional controlada (não desktop pessoal), nomenclatura padronizada (OS, período, data de extração), prazo de retenção e descarte, vedação a envio por canais pessoais.
- **Uso de assistentes de IA**: permitido para redação e explicação de consultas; **vedada** a inserção de dados de contribuintes no prompt; conferência obrigatória do resultado por contagem de controle; registro no relatório de que houve auxílio de ferramenta.
- **Reprodutibilidade**: toda apuração que instrua procedimento fiscal deve ser acompanhada do script `.sql` ou do arquivo `.pq`/`.pbix` com as etapas, dos parâmetros usados e da data/hora da extração, anexados ao processo.
- **Revisão por pares** para cruzamentos que fundamentem lavratura, com conferência independente do resultado.

---

*Gabarito do Módulo 10 — Curso de Banco de Dados Relacional aplicado à Fiscalização Tributária.*
