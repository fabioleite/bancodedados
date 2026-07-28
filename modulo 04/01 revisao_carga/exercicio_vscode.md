# Material Complementar — Recursos Visuais e Low-Code do VS Code com a Extensão MSSQL

**Curso de Integridade Fiscal — Banco de Dados `curso_integridade_fiscal`**
**Complementa os módulos de BULK INSERT, ALTER TABLE e o exercício integrador**

---

## 1. Objetivo

Todos os módulos anteriores do curso foram construídos em torno da escrita direta de comandos T-SQL (`BULK INSERT`, `CREATE TABLE`, `ALTER TABLE`, `UPDATE`). Esse caminho é essencial para entender o que acontece "por baixo do capô" — mas no dia a dia da auditoria fiscal, muitas dessas tarefas podem ser resolvidas mais rapidamente por interfaces gráficas, sem abrir mão da precisão técnica.

Este material apresenta os recursos **visuais e low-code** da extensão MSSQL para VS Code: assistentes de importação, editores de dados em grade (estilo planilha), e designers de tabela e de esquema com diagramação e arrastar-e-soltar. A ideia não é substituir o T-SQL — é saber quando cada abordagem é mais eficiente.

![Extensão MSSQL instalada no Visual Studio Code](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/media/mssql-extension-visual-studio-code/mssql-extension-vscode.png?view=sql-server-ver17)
*A extensão MSSQL instalada e ativa no VS Code — o ícone na Activity Bar e a vista de Conexões confirmam a instalação. Fonte: Microsoft Learn.*

---

## 2. Panorama dos recursos

<cite index="15-1">A extensão MSSQL para Visual Studio Code fornece ferramentas para conectar a bancos de dados, gerenciar e desenhar esquemas, explorar objetos do banco de dados, executar consultas T-SQL e visualizar planos de execução.</cite> Os recursos relevantes para um fluxo de trabalho **low-code** são:

| Recurso | O que substitui em T-SQL | Situação |
|---|---|---|
| Importar Arquivo Plano (Flat File Import) | `BULK INSERT` | Disponibilidade geral |
| Table Designer | `CREATE TABLE` / `ALTER TABLE` | Disponibilidade geral |
| Schema Designer | `CREATE TABLE` com `FOREIGN KEY`, diagramação de modelo | Disponibilidade geral |
| Visualizar & Editar Dados | `INSERT` / `UPDATE` / `DELETE` simples | Disponibilidade geral |
| Explorador de Objetos com filtros | Consultas em `sys.tables`, `sys.columns` | Disponibilidade geral |
| Schema Designer com GitHub Copilot | Modelagem inteira a partir de linguagem natural | Disponibilidade geral |

---

## 3. Importação de CSV sem escrever BULK INSERT

O assistente **Importar Arquivo Plano** (*Flat File Import*) é o equivalente visual direto do que foi feito manualmente no módulo de BULK INSERT.

Antes da importação, a conexão com o banco é feita pela caixa de diálogo de conexão da extensão:

![Caixa de diálogo de conexão da extensão MSSQL no VS Code](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/media/mssql-extension-visual-studio-code/mssql-connection-dialog-parameters.png?view=sql-server-ver17)
*Tela de conexão — permite conectar por parâmetros, string de conexão ou navegando pelo Azure. Fonte: Microsoft Learn.*

**Como acessar o assistente:** no Object Explorer (vista de Conexões), expanda a conexão e o nó **Databases**, clique com o botão direito no banco de dados de destino e selecione **Import flat file**.

![Menu de contexto com a opção Import flat file no Object Explorer do VS Code](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/media/mssql-database-operations/flat-file-import-entry.png?view=sql-server-ver17)
*Ponto de entrada do assistente — botão direito no banco de dados → Import flat file. Fonte: Microsoft Learn.*

O assistente conduz o usuário por etapas:

**Passo 1 — Especificar o arquivo de entrada:** informe o banco de destino, o caminho do arquivo `.csv`/`.txt`, o nome da nova tabela e o schema (ex.: `dbo`).

![Tela do assistente de importação de arquivo mostrando a configuração do arquivo de entrada](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/media/mssql-database-operations/flat-file-dialog.png?view=sql-server-ver17)

**Passo 2 — Pré-visualizar os dados:** <cite index="11-1">a extensão detecta automaticamente os nomes de colunas e os tipos de dados</cite>, poupando a etapa manual de decidir se cada coluna é `VARCHAR`, `INT`, `DATE`, etc. Esta tela permite validar o alinhamento das colunas e o delimitador usado antes de prosseguir.

![Tela do assistente de importação de arquivo mostrando a pré-visualização dos dados com colunas inferidas](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/media/mssql-database-operations/flat-file-preview.png?view=sql-server-ver17)

**Passo 3 — Modificar colunas:** <cite index="11-1">é possível ajustar nomes de colunas, tipos de dados, chaves primárias e nulidade</cite> antes de confirmar.

![Tela do assistente de importação de arquivo mostrando as opções de modificação de colunas](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/media/mssql-database-operations/flat-file-modify.png?view=sql-server-ver17)

Ao selecionar **Import Data**: <cite index="11-1">a tabela é criada e os dados são importados em um único fluxo contínuo</cite>, sem exigir um `CREATE TABLE` prévio nem a instrução `BULK INSERT`.

*Fonte das capturas de tela desta seção: tutorial oficial "Database Operations — MSSQL Extension for Visual Studio Code" — Microsoft Learn.*

**Aplicação no cenário do curso:** ao receber o arquivo `nfe_importacao_lote.csv` do exercício integrador, em vez de escrever manualmente o `CREATE TABLE stg_nfe_importacao` e depois o `BULK INSERT`, o auditor poderia:

- Clicar com o botão direito no banco `curso_integridade_fiscal` → **Import Flat File**;
- Apontar para o CSV e deixar o assistente inferir os tipos;
- Ajustar manualmente `valor_total` e `data_emissao` para `VARCHAR` (já que o arquivo contém erros propositais) — o mesmo raciocínio do módulo anterior, só que decidido visualmente, clicando no tipo da coluna em vez de escrevê-lo;
- Concluir o assistente, que cria a tabela e carrega as 40 linhas automaticamente.

**Quando preferir o assistente em vez do `BULK INSERT` manual:** cargas pontuais, exploratórias, ou quando o formato do arquivo ainda não é totalmente conhecido (o assistente ajuda a descobrir a estrutura). **Quando preferir o `BULK INSERT` escrito:** cargas repetitivas, agendadas, ou que precisam ser versionadas como script (ex.: parte de uma rotina de ETL documentada).

---

## 4. Table Designer — criando e alterando tabelas visualmente

O **Table Designer** oferece uma interface para o que os módulos de modelagem e de `ALTER TABLE` fizeram via código.

**Como acessar:** botão direito em **Tables** no Object Explorer → **New Table** (para criar) ou botão direito em uma tabela existente → **Design** (para alterar).

Principais capacidades da interface:

- **Colunas** — <cite index="15-1">adicionar novas colunas, definir tipos de dados, definir a anulabilidade e especificar valores padrão, além de designar uma coluna como chave primária ou coluna de identidade diretamente na interface</cite>;
- **Chave primária** — <cite index="15-1">definir uma ou mais colunas como chave primária da tabela</cite>;
- **Índices** — <cite index="15-1">criar e gerenciar índices para melhorar o desempenho das consultas</cite>;
- **Chaves estrangeiras** — <cite index="15-1">definir relacionamentos entre tabelas referenciando chaves primárias de outras tabelas</cite>;
- **Check constraints** — configurar regras de validação (equivalente visual ao `CHECK` que foi usado no exercício integrador para `status_validacao`).

Um diferencial importante: o designer mantém um painel **Script como Criar**, que mostra em tempo real o T-SQL equivalente a cada alteração feita visualmente. Isso significa que o material continua "auditável" — o auditor pode clicar para montar a tabela e, ao final, copiar ou revisar o script gerado antes de aplicá-lo, com a opção de **Publicar** (aplica direto no banco) ou **Copiar script** (para versionar ou ajustar manualmente).

![Interface do Table Designer no VS Code mostrando colunas, tipos de dados e o painel de script](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/media/mssql-extension-visual-studio-code/table-designer.png?view=sql-server-ver17)
*Table Designer aberto no VS Code — grade de colunas à esquerda e painel de script T-SQL gerado à direita. Fonte: Microsoft Learn.*

**Aplicação no cenário do curso:** as colunas de controle adicionadas no exercício integrador (`status_validacao`, `motivo_rejeicao`, `data_analise`, `auditor_responsavel`, e a constraint de `CHECK`) poderiam ter sido adicionadas inteiramente pelo Table Designer, sem escrever nenhum `ALTER TABLE` — bastando abrir a tabela em modo de edição, clicar em "adicionar coluna" quatro vezes e configurar a constraint na aba correspondente.

---

## 5. Schema Designer — modelagem visual com diagrama

O **Schema Designer** vai além de uma tabela isolada: ele apresenta o banco inteiro como um diagrama interativo, no estilo dos diagramas ER trabalhados nos módulos de modelagem relacional.

![Visão geral do Schema Designer no VS Code mostrando um diagrama de banco de dados](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/media/mssql-schema-designer/schema-designer-overview.png?view=sql-server-ver17)
*Visão geral do canvas do Schema Designer, com várias tabelas e seus relacionamentos exibidos como um diagrama. Fonte: Microsoft Learn.*

**Como acessar:** clique com o botão direito no banco de dados no Object Explorer e selecione **Visualize and Design Schema**.

![Menu de contexto mostrando a opção para abrir o Schema Designer no VS Code](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/media/mssql-schema-designer/schema-designer-entry-point.png?view=sql-server-ver17)

Recursos principais:

- <cite index="9-1">Interface visual para criar e gerenciar múltiplas tabelas simultaneamente, com disposição automática das tabelas no diagrama</cite>;
- Arrastar e soltar para reposicionar tabelas e reorganizar visualmente o modelo, além de recursos de busca, filtro, zoom e um mini-mapa para diagramas grandes;
- Criação de relacionamentos (chaves estrangeiras) desenhando uma linha entre colunas de tabelas diferentes, em vez de escrever `FOREIGN KEY REFERENCES`;
- Geração automática do script T-SQL correspondente ao diagrama, para revisão antes de publicar.

Cada tabela no diagrama exibe seu nome, colunas, tipos de dados e a chave primária (identificada por um ícone de chave):

![Estrutura de uma tabela no Schema Designer mostrando colunas, tipos de dados e chave primária](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/media/mssql-schema-designer/schema-designer-tables.png?view=sql-server-ver17)

Para editar uma tabela, basta clicar no ícone de lápis, o que abre o painel **Table Editor** ao lado do canvas:

![Painel do editor de tabela no Schema Designer para adicionar ou modificar detalhes da tabela](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/media/mssql-schema-designer/schema-designer-edit-table.png?view=sql-server-ver17)

Os relacionamentos entre tabelas (chaves estrangeiras) podem ser gerenciados por um painel dedicado, ou desenhados diretamente arrastando uma seta de uma coluna a outra no diagrama:

![Painel de gerenciamento de chaves estrangeiras no Schema Designer](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/media/mssql-schema-designer/schema-designer-foreign-key.png?view=sql-server-ver17)

![Setas representando relacionamentos de chave estrangeira entre tabelas no diagrama do Schema Designer](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/media/mssql-schema-designer/schema-designer-arrows.png?view=sql-server-ver17)

Ao final da modelagem, o botão **Publish Changes** mostra um resumo de todas as alterações pendentes antes de aplicá-las ao banco:

![Tela de resumo de alterações do Schema Designer antes de publicar no banco](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/media/mssql-schema-designer/schema-designer-publish.png?view=sql-server-ver17)

*Fonte das capturas de tela desta seção: tutorial oficial "Schema Designer — MSSQL Extension for Visual Studio Code" — Microsoft Learn.*

**Recurso avançado — Schema Designer com GitHub Copilot:** <cite index="10-1">a integração com o GitHub Copilot permite desenhar e evoluir esquemas de banco de dados usando linguagem natural diretamente no canvas visual</cite>. Em vez de adicionar tabelas, colunas e relacionamentos manualmente pela interface, <cite index="10-1">é possível descrever o que se precisa em português (ou inglês) e o Copilot gera as tabelas, colunas, tipos de dados e relacionamentos automaticamente, refletidos em tempo real tanto no diagrama visual quanto no script T-SQL</cite>.

**Aplicação no cenário do curso:** o conjunto de entidades reutilizado em todos os módulos (`contribuinte`, `nfe`, `auto_infracao`, `auditor_fiscal`) poderia ser recriado do zero desenhando as quatro tabelas no canvas do Schema Designer, arrastando uma linha de `nfe.cnpj_emitente` até `contribuinte.cnpj` para materializar visualmente a chave estrangeira — o mesmo relacionamento que, em T-SQL, exigiria escrever a cláusula `FOREIGN KEY ... REFERENCES`.

---

## 6. Visualizar & Editar Dados — correção de dados sem UPDATE

Este é o recurso mais diretamente comparável ao módulo de `UPDATE`/`DELETE`.

**Como acessar:** botão direito em uma tabela no Object Explorer → **Edit Data** (também acessível dando um duplo clique na tabela).

<cite index="15-1">Os dados da tabela abrem em uma grade dentro de uma aba do editor, em um layout semelhante a uma planilha, com navegação por páginas.</cite> Capacidades principais:

![Tela de edição de dados em grade no VS Code, estilo planilha](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/media/mssql-extension-visual-studio-code/edit-data.png?view=sql-server-ver17)
*Grade de edição de dados aberta em uma aba do editor — layout semelhante a uma planilha, com paginação e o painel de script correspondente. Fonte: Microsoft Learn.*

- **Edição em linha** — <cite index="15-1">atualizar valores de células diretamente na grade, com validação em tempo real que sinaliza em vermelho entradas inválidas, como tipos de dados incorretos ou violações de constraint</cite>;
- **Adicionar e excluir linhas** — inserir ou remover registros sem escrever `INSERT`/`DELETE`;
- **Paginação** — navegar por grandes volumes de dados sem carregar tudo de uma vez;
- **Salvar alterações** — <cite index="15-1">as edições ficam pendentes até que o usuário selecione "Salvar Alterações", mantendo controle total sobre quando as atualizações são gravadas no banco</cite>;
- **Mostrar script** — <cite index="15-1">um painel apresenta, em modo somente leitura, o script DML equivalente a todas as ações feitas na grade</cite> — ou seja, mesmo corrigindo dados visualmente, é possível auditar exatamente qual `UPDATE`/`INSERT`/`DELETE` foi gerado.

**Importante para o contexto de auditoria fiscal:** essa "prestação de contas" via **Mostrar Script** é o que torna o recurso apropriado mesmo em um ambiente que exige rastreabilidade — nenhuma alteração acontece "invisível"; o T-SQL equivalente sempre pode ser conferido antes ou depois de salvar.

**Limitação a ter em mente:** correções em massa baseadas em regra de negócio (como os itens 7.1 a 7.7 do exercício integrador, que aplicam uma condição a dezenas de linhas de uma vez) continuam sendo mais eficientes em T-SQL puro. O editor em grade é ideal para correções pontuais, linha a linha — não para regras de triagem aplicadas a um lote inteiro.

---

## 7. Explorador de Objetos com filtros

Para localizar rapidamente tabelas, views e outros objetos em um banco com muitos elementos — situação comum à medida que o curso acumula módulos sobre o mesmo `curso_integridade_fiscal` — <cite index="15-1">o Object Explorer permite aplicar filtros por propriedades como nome, proprietário ou data de criação, em múltiplos níveis da hierarquia do banco</cite>. É a alternativa visual a escrever consultas em `sys.tables` ou `sys.columns` para localizar objetos.

![Recurso de filtro do Object Explorer no VS Code](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/media/mssql-extension-visual-studio-code/object-explorer-filtering.png?view=sql-server-ver17)
*Filtros aplicados ao Object Explorer para restringir a lista de objetos exibidos. Fonte: Microsoft Learn.*

---

## 8. Quando usar cada abordagem

| Situação | Abordagem recomendada |
|---|---|
| Carga exploratória de um CSV novo, formato ainda incerto | Import Flat File (assistente) |
| Carga repetitiva, agendada, documentada como script | `BULK INSERT` escrito |
| Criar uma tabela nova rapidamente | Table Designer |
| Desenhar o modelo relacional completo de um novo módulo | Schema Designer |
| Corrigir 1 a 3 registros específicos | Visualizar & Editar Dados |
| Corrigir dezenas/centenas de registros por regra de negócio | `UPDATE` com `WHERE` |
| Entender o que uma constraint realmente faz | Escrever o `ALTER TABLE ... CHECK` manualmente ao menos uma vez |

---

## 9. Para refletir

- Em uma rotina real de auditoria da SEFAZ-PB, quais tarefas ganhariam mais em velocidade usando os assistentes visuais, e quais exigem que o script T-SQL fique documentado e versionado?
- O painel **Mostrar Script** do editor de dados resolve completamente a preocupação de rastreabilidade, ou ainda haveria vantagem em manter os `UPDATE`s de triagem como scripts formais, como os do exercício integrador?
- Que riscos existem em depender só da inferência automática de tipos do assistente de importação, sem revisar manualmente o esquema sugerido — especialmente diante de um arquivo com erros propositais, como o do exercício integrador?

---

## 10. Referências

Todas as capturas de tela e descrições técnicas deste material foram retiradas da documentação oficial da Microsoft (Microsoft Learn), atualizada em 2025-2026:

1. Microsoft Learn — *Overview - MSSQL Extension for Visual Studio Code*. Disponível em: https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/mssql-extension-visual-studio-code?view=sql-server-ver17

2. Microsoft Learn — *Database Operations - MSSQL Extension for Visual Studio Code* (Import Flat File). Disponível em: https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/mssql-database-operations?view=sql-server-ver17

3. Microsoft Learn — *Schema Designer - MSSQL Extension for Visual Studio Code*. Disponível em: https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/mssql-schema-designer?view=sql-server-ver17

4. Microsoft Learn — *Schema Designer with GitHub Copilot*. Disponível em: https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/mssql-schema-designer-copilot?view=sql-server-ver17

5. Azure SQL Dev Corner (Microsoft DevBlogs) — *MSSQL Extension for VS Code: Introducing Schema Designer (Preview)*. Disponível em: https://devblogs.microsoft.com/azure-sql/vs-code-mssql-schema-designer/

6. Azure SQL Dev Corner (Microsoft DevBlogs) — *MSSQL Extension for VS Code: SQL Notebooks, AI-Powered Schema Design, Data API builder & More*. Disponível em: https://devblogs.microsoft.com/azure-sql/vscode-mssql-march-2026/

7. Microsoft — *What's Happening with Azure Data Studio*. Disponível em: https://learn.microsoft.com/en-us/sql/tools/whats-happening-azure-data-studio?view=sql-server-ver17

> **Nota sobre as imagens:** todas as capturas de tela reproduzidas neste documento são hotlinks para os arquivos de imagem hospedados oficialmente pela Microsoft em learn.microsoft.com, extraídos diretamente dos tutoriais públicos indicados acima — não foram usadas capturas de tela de terceiros ou de fontes não oficiais.
