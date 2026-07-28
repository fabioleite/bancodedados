# Material Complementar — Recursos Visuais e Low-Code do SQL Server Management Studio (SSMS)

**Curso de Integridade Fiscal — Banco de Dados `curso_integridade_fiscal`**
**Complementa os módulos de BULK INSERT, ALTER TABLE, UPDATE/DELETE e o material equivalente sobre VS Code**

---

## 1. Objetivo

Este material espelha o anterior (sobre VS Code + extensão MSSQL), mas focado no **SSMS**, a ferramenta de administração tradicional do SQL Server. O SSMS também oferece assistentes e designers visuais que reduzem — ou eliminam — a necessidade de escrever T-SQL manualmente para tarefas de carga, alteração de estrutura e correção de dados. Algumas dessas ferramentas existem no SSMS há mais tempo que suas equivalentes no VS Code, e vale conhecer tanto o potencial quanto as limitações de cada uma.

---

## 2. Panorama dos recursos

| Recurso | O que substitui em T-SQL | Onde encontrar |
|---|---|---|
| Import Flat File Wizard | `BULK INSERT` (carga simples) | Botão direito no banco → Tasks → Import Flat File |
| Import and Export Wizard (SSIS) | `BULK INSERT` / ETL mais robusto | Botão direito no banco → Tasks → Import Data / Export Data |
| Table Designer | `CREATE TABLE` / `ALTER TABLE` | Botão direito na tabela → Design |
| Database Diagram Designer | `CREATE TABLE` com `FOREIGN KEY`, diagramação do modelo | Pasta "Database Diagrams" → New Database Diagram |
| Edit Top 200 Rows | `UPDATE` / `INSERT` / `DELETE` pontuais | Botão direito na tabela → Edit Top 200 Rows |
| Generate Scripts Wizard | Documentar/reaplicar `CREATE TABLE` já existente | Botão direito no banco → Tasks → Generate Scripts |

---

## 3. Importação de CSV sem escrever BULK INSERT

O SSMS oferece **dois** assistentes de importação, com propósitos diferentes — vale entender quando usar cada um.

### 3.1 Import Flat File Wizard

Focado especificamente em arquivos `.csv` e `.txt`, simples e rápido.

**Como acessar:** Object Explorer → botão direito no banco → **Tasks** → **Import Flat File**.

![Menu para acessar o Import Flat File Wizard no SSMS](https://learn.microsoft.com/en-us/sql/relational-databases/import-export/media/import-flat-file-wizard/import-flat-file-menu.png?view=sql-server-ver17)
*Acesso ao assistente pelo menu de contexto do banco (Tasks → Import Flat File). Fonte: Microsoft Learn.*

Funcionamento: <cite index="18-1">o assistente foi criado para melhorar a experiência de importação usando um framework de inferência chamado PROSE (Program Synthesis using Examples), que analisa os padrões dos dados no arquivo de entrada para inferir nomes de colunas, tipos, delimitadores e outras características, poupando o usuário desse trabalho manual</cite>. Na prática, o fluxo é:

1. **Tela de introdução do assistente:**

   ![Tela de introdução do Import Flat File Wizard](https://learn.microsoft.com/en-us/sql/relational-databases/import-export/media/import-flat-file-wizard/import-flat-file-intro.png?view=sql-server-ver17)

2. **Seleção do arquivo de entrada:**

   ![Tela de seleção do arquivo no Import Flat File Wizard](https://learn.microsoft.com/en-us/sql/relational-databases/import-export/media/import-flat-file-wizard/import-flat-file-specify.png?view=sql-server-ver17)

3. **Pré-visualização dos dados** — <cite index="18-1">o assistente gera uma pré-visualização das primeiras 50 linhas para conferência antes de prosseguir</cite>:

   ![Tela de pré-visualização de dados do Import Flat File Wizard](https://learn.microsoft.com/en-us/sql/relational-databases/import-export/media/import-flat-file-wizard/import-flat-file-preview.png?view=sql-server-ver17)

4. **Revisão do esquema inferido** — <cite index="18-1">é possível corrigir campos identificados incorretamente, como um tipo que deveria ser `float` e foi inferido como `int`, e colunas com valores vazios detectados já vêm com "Allow Nulls" marcado automaticamente</cite>:

   ![Tela de modificação de colunas do Import Flat File Wizard](https://learn.microsoft.com/en-us/sql/relational-databases/import-export/media/import-flat-file-wizard/import-flat-file-modify.png?view=sql-server-ver17)

5. **Conclusão e resultado da importação:**

   ![Tela de resultado do Import Flat File Wizard](https://learn.microsoft.com/en-us/sql/relational-databases/import-export/media/import-flat-file-wizard/import-flat-file-results.png?view=sql-server-ver17)

*Sequência de telas do assistente. Fonte: tutorial oficial "Import Flat File to SQL" — Microsoft Learn.*

**Aplicação no curso:** é o equivalente direto, dentro do SSMS, ao assistente **Import Flat File** apresentado no material do VS Code — mesma lógica de inferência automática, mesma ideia de dispensar o `CREATE TABLE` + `BULK INSERT` manuais para cargas simples e exploratórias, como o `nfe_importacao_lote.csv` do exercício integrador.

### 3.2 SQL Server Import and Export Wizard

Mais robusto e genérico — não se limita a arquivos `.csv`, e não se limita a importar (também exporta).

**Como acessar:** Object Explorer → botão direito no banco → **Tasks** → **Import Data** (ou **Export Data**).

Diferenças em relação ao Import Flat File:

- <cite index="17-1">permite importar dados de e exportar dados para diversas origens e destinos, incluindo arquivos simples e outros formatos, bancos de dados relacionais e serviços de nuvem</cite> — não só CSV, mas também Excel, Access, outras instâncias de SQL Server, etc.;
- <cite index="23-1">ao final do processo, é possível salvar o resultado como um pacote SSIS, que pode ser reaproveitado e estendido posteriormente com o SSIS Designer para adicionar tarefas, transformações e lógica orientada a eventos</cite> — ou seja, diferente do Import Flat File, este assistente pode virar uma rotina reutilizável e agendável;
- Requer <cite index="17-1">SQL Server Integration Services (SSIS) ou SQL Server Data Tools (SSDT) instalados</cite> para funcionar por completo.

**Telas do assistente (exemplo oficial da Microsoft — importação de uma planilha Excel para o SQL Server):**

![Tela inicial do SQL Server Import and Export Wizard](https://learn.microsoft.com/en-us/sql/integration-services/import-export-data/media/welcome-to-the-wizard.jpg?view=sql-server-ver17)
*Tela de boas-vindas do assistente.*

![Tela de seleção de origem de dados no Import and Export Wizard](https://learn.microsoft.com/en-us/sql/integration-services/import-export-data/media/choose-the-excel-data-source.jpg?view=sql-server-ver17)
*Seleção da origem dos dados — no exemplo oficial, um arquivo Excel; no caso do curso, seria o CSV do lote de NF-e.*

![Tela de seleção de tabelas de origem no Import and Export Wizard](https://learn.microsoft.com/en-us/sql/integration-services/import-export-data/media/select-the-table-before-renaming.jpg?view=sql-server-ver17)
*Seleção da tabela/planilha de origem e mapeamento para a tabela de destino.*

![Tela de pré-visualização de dados no Import and Export Wizard](https://learn.microsoft.com/en-us/sql/integration-services/import-export-data/media/preview-data-to-copy.jpg?view=sql-server-ver17)
*Pré-visualização dos dados antes da execução — equivalente à etapa de conferência do Import Flat File Wizard.*

*Fonte das capturas de tela: tutorial oficial "Get started with this simple example of the Import and Export Wizard" — Microsoft Learn.*

**Quando usar cada um:**

| Cenário | Ferramenta |
|---|---|
| CSV simples, uso único, quer rapidez | Import Flat File Wizard |
| Origem não é CSV (Excel, outro SQL Server, nuvem) | Import and Export Wizard |
| Precisa reaproveitar a rotina de carga periodicamente | Import and Export Wizard (salvando como pacote SSIS) |
| Quer o mínimo de configuração possível | Import Flat File Wizard |

---

## 4. Table Designer — criando e alterando tabelas visualmente

**Como acessar:** para criar, botão direito em **Tables** → **New Table**; para alterar uma tabela existente, botão direito na tabela → **Design**.

<cite index="29-1">O Table Designer possui duas áreas: uma grade superior, em que cada linha descreve uma coluna da tabela com seus atributos fundamentais — nome, tipo de dado e permissão de nulos — e uma aba de Propriedades da Coluna na parte inferior, que mostra atributos adicionais da coluna selecionada na grade</cite>.

Nesta interface é possível:

- Adicionar, renomear ou remover colunas simplesmente editando linhas da grade;
- Definir a chave primária clicando com o botão direito na linha da coluna desejada e escolhendo **Set Primary Key**;
- Configurar valores padrão, comprimento de campos de texto, precisão de campos numéricos e outras propriedades pela aba de propriedades;
- Criar índices, chaves estrangeiras e check constraints pelos ícones da barra de ferramentas do designer (ou pelo menu **Table Designer** que aparece ao abrir a tela);
- Ao salvar, o SSMS solicita confirmação e aplica as alterações diretamente — nos bastidores, ele gera e executa o `ALTER TABLE` equivalente. Há a opção **Generate Change Script**, que exibe esse script antes de aplicá-lo, útil para revisão em ambientes fiscais que exigem rastreabilidade.

**Aplicação no curso:** as quatro colunas de controle acrescentadas em `stg_nfe_importacao` no exercício integrador (`status_validacao`, `motivo_rejeicao`, `data_analise`, `auditor_responsavel`) poderiam ter sido adicionadas clicando em linhas em branco da grade do Table Designer, sem escrever nenhum `ALTER TABLE ADD`.

---

## 5. Database Diagram Designer — modelagem visual com diagrama

**Como acessar:** Object Explorer → expanda o banco → botão direito na pasta **Database Diagrams** → **New Database Diagram**.

<cite index="33-1">O Database Diagram Designer permite criar, editar ou excluir tabelas, colunas, chaves, índices, relacionamentos e restrições de forma visual, e é possível criar quantos diagramas forem necessários, cada um ilustrando uma parte ou a totalidade das tabelas do banco</cite>.

![Diagrama mostrando relacionamentos entre tabelas no Database Diagram Designer do SSMS](https://learn.microsoft.com/en-us/ssms/visual-db-tools/media/design-database-diagrams-visual-database-tools/table-relationships.png)
*Exemplo de diagrama com tabelas relacionadas — cada linha representa uma chave estrangeira entre tabelas. Fonte: Microsoft Learn.*

Recursos principais:

- Arrastar tabelas existentes do Object Explorer diretamente para o diagrama;
- Criar relacionamentos (chaves estrangeiras) arrastando uma linha de uma coluna a outra entre tabelas — <cite index="33-1">os pontos finais da linha de relacionamento indicam se a relação é um-para-um ou um-para-muitos</cite>;
- Múltiplas visualizações de cada tabela (com mais ou menos colunas visíveis), úteis para simplificar diagramas grandes;
- Salvar o diagrama como um objeto do próprio banco, reaproveitável em sessões futuras do SSMS.

**Limitação a registrar:** este é um recurso mais antigo e menos ativamente atualizado que o Schema Designer do VS Code — não conta, por exemplo, com integração de IA generativa. Ainda assim, cumpre bem o papel de visualizar e criar relacionamentos sem escrever `FOREIGN KEY REFERENCES` manualmente.

**Aplicação no curso:** o mesmo exercício sugerido no material do VS Code — recriar visualmente o relacionamento entre `nfe.cnpj_emitente` e `contribuinte.cnpj` — pode ser feito aqui arrastando as duas tabelas para o diagrama e desenhando a linha de relacionamento entre as colunas correspondentes.

---

## 6. Edit Top 200 Rows — correção de dados sem UPDATE

**Como acessar:** botão direito na tabela → **Edit Top 200 Rows**.

<cite index="26-1">Isso abre uma visão de planilha editável com as 200 primeiras linhas da tabela</cite>. É o recurso mais próximo, dentro do SSMS, do "Visualizar & Editar Dados" do VS Code — com uma particularidade importante: **o limite de 200 linhas é literal por padrão**, e vale entender como contorná-lo.

**Editando além das 200 linhas exibidas:** <cite index="26-1">as abas abertas por esse recurso funcionam em modo "Query Designer", que adiciona um menu correspondente à barra de menus, com quatro painéis que podem ser mostrados ou ocultados</cite>. Um desses painéis mostra o SQL (`SELECT TOP 200 ...`) que gera a grade — e ele pode ser editado diretamente para remover a cláusula `TOP 200`, adicionar um `WHERE`, ou alterar a ordenação, sem sair da visão em grade.

**Alterando o padrão de 200 linhas permanentemente:** <cite index="27-1">em Tools → Options, dentro de SQL Server Object Explorer → Commands, é possível alterar os valores padrão de 200 (edição) e 1000 (seleção) — inclusive definindo 0 para remover o limite completamente</cite>.

Capacidades da grade:

- Edição célula a célula, com o valor sendo aplicado ao banco assim que se sai da célula (diferente do VS Code, que exige um "Salvar Alterações" explícito — no SSMS a gravação é mais imediata, o que pede atenção redobrada);
- Inserção de novas linhas na linha em branco ao final da grade;
- Exclusão de linhas selecionando o seletor à esquerda e pressionando Delete;
- Botão de **diagrama da tabela**, que permite ocultar colunas da visão sem afetar o banco;
- Botão de **SQL**, que revela e permite editar a consulta subjacente.

**Cuidado importante para o contexto de auditoria fiscal:** ao contrário do editor do VS Code (que mantém as alterações pendentes até um "Salvar" explícito e mostra o script DML completo antes de gravar), o Edit Top 200 Rows do SSMS **grava a alteração assim que o cursor sai da célula editada** — não há uma etapa de confirmação em lote nem um script DML consolidado para revisão prévia. Isso o torna adequado para correções pontuais e rápidas, mas menos indicado quando a rastreabilidade da alteração precisa ser revisada antes de ser efetivada.

**Aplicação no curso:** corrigir manualmente 2 ou 3 registros isolados de `stg_nfe_importacao` — por exemplo, um erro de digitação identificado numa única linha — é mais rápido pelo Edit Top 200 Rows do que escrevendo um `UPDATE` com `WHERE`. Já a triagem em lote dos itens 7.1 a 7.7 do exercício integrador continua sendo tarefa para T-SQL puro, pois depende de condições aplicadas a múltiplas linhas simultaneamente.

---

## 7. Generate Scripts Wizard — reaproveitando estrutura sem redigitar

Embora não seja, estritamente, um substituto do `ALTER TABLE`, este assistente merece menção porque reduz drasticamente a necessidade de **redigitar manualmente** definições de tabelas já existentes.

**Como acessar:** botão direito no banco (ou numa tabela específica) → **Tasks** → **Generate Scripts**.

O assistente conduz por um fluxo guiado de seleção de objetos (tabelas, views, procedures) e opções de script (incluir dados, incluir índices, incluir constraints), gerando ao final um arquivo `.sql` completo com o `CREATE TABLE` — ou `INSERT`s — correspondente. Isso é útil, por exemplo, para:

- Documentar a estrutura final de `stg_nfe_importacao` depois de todas as alterações do exercício integrador, sem ter que redigitar manualmente cada `ALTER TABLE` aplicado ao longo do processo;
- Recriar a mesma estrutura em outro ambiente (por exemplo, replicar o banco `curso_integridade_fiscal` em uma máquina de outro auditor) sem depender de memória ou de scripts dispersos.

---

## 8. Quando usar cada abordagem

| Situação | Abordagem recomendada |
|---|---|
| Carga simples de um CSV, uso único | Import Flat File Wizard |
| Carga de fonte não-CSV, ou rotina a ser reaproveitada/agendada | Import and Export Wizard (salvando como pacote SSIS) |
| Criar ou alterar a estrutura de uma tabela | Table Designer |
| Visualizar/desenhar relacionamentos entre várias tabelas | Database Diagram Designer |
| Corrigir 1 a 3 registros pontuais, sem necessidade de revisão prévia do DML | Edit Top 200 Rows |
| Corrigir dezenas/centenas de registros por regra de negócio | `UPDATE` com `WHERE` |
| Documentar ou reaplicar uma estrutura já existente | Generate Scripts Wizard |
| Alteração que precisa ficar registrada e revisável antes de gravar | Script T-SQL manual (ou o painel de revisão do VS Code) |

---

## 9. SSMS x VS Code — nota de comparação rápida

| Aspecto | SSMS | VS Code + extensão MSSQL |
|---|---|---|
| Plataforma | Apenas Windows | Windows, macOS, Linux |
| Edição de dados em grade | Grava célula a célula, sem lote de confirmação | Mantém edições pendentes até "Salvar Alterações", com script DML exibido antes |
| Diagrama de esquema | Database Diagram Designer (mais simples, mais antigo) | Schema Designer (moderno, com IA generativa opcional) |
| Importação de CSV | Dois assistentes (Flat File e Import/Export) | Um assistente (Flat File), mais direto |
| Reaproveitamento como rotina agendável | Sim, via pacote SSIS | Não é o foco principal da extensão |

Nenhuma das duas ferramentas é estritamente "melhor" — no ambiente da SEFAZ-PB, o SSMS tende a ser mais familiar para tarefas administrativas do dia a dia, enquanto o VS Code se destaca quando a rastreabilidade das edições (script DML explícito antes de gravar) é prioridade, como costuma ser o caso em rotinas de auditoria.

---

## 10. Para refletir

- Dado que o Edit Top 200 Rows grava alterações imediatamente, célula a célula, que cuidados um auditor deveria adotar antes de usá-lo para corrigir dados de produção?
- Em que momento vale a pena transformar uma importação feita pelo Import and Export Wizard em um pacote SSIS reutilizável, em vez de repetir o assistente manualmente a cada novo lote?
- Comparando o Database Diagram Designer do SSMS com o Schema Designer do VS Code (visto no material anterior), em que cenário a diagramação mais simples do SSMS já seria suficiente, e em que cenário a modelagem assistida por IA do VS Code agregaria mais valor?

---

## 11. Referências

Todas as capturas de tela e descrições técnicas deste material foram retiradas da documentação oficial da Microsoft (Microsoft Learn), atualizada em 2025-2026:

1. Microsoft Learn — *Import Flat File to SQL Wizard*. Disponível em: https://learn.microsoft.com/en-us/sql/relational-databases/import-export/import-flat-file-wizard?view=sql-server-ver17

2. Microsoft Learn — *Get started with this simple example of the Import and Export Wizard*. Disponível em: https://learn.microsoft.com/en-us/sql/integration-services/import-export-data/get-started-with-this-simple-example-of-the-import-and-export-wizard?view=sql-server-ver17

3. Microsoft Learn — *Import and Export Data with the SQL Server Import and Export Wizard*. Disponível em: https://learn.microsoft.com/en-us/sql/integration-services/import-export-data/import-and-export-data-with-the-sql-server-import-and-export-wizard?view=sql-server-ver17

4. Microsoft Learn — *Visual Database Tool Designers*. Disponível em: https://learn.microsoft.com/en-us/ssms/visual-db-tools/visual-database-tool-designers

5. Microsoft Learn — *Create and Update Tables (Visual Database Tools)*. Disponível em: https://learn.microsoft.com/en-us/ssms/visual-db-tools/design-tables-visual-database-tools

6. Microsoft Learn — *Design Database Diagrams (Visual Database Tools)*. Disponível em: https://learn.microsoft.com/en-us/ssms/visual-db-tools/design-database-diagrams-visual-database-tools

7. Microsoft Learn — *Options (SQL Server Object Explorer/Commands)* — parâmetros de "Edit Top N Rows". Disponível em: https://learn.microsoft.com/en-us/previous-versions/sql/sql-server-2008-r2/cc280381(v=sql.105)

8. nolongerset.com — *Editing Data Directly in SSMS* (uso do modo "Query Designer" ao editar linhas). Disponível em: https://nolongerset.com/editing-data-in-ssms/

9. Schneider Electric USA — *How to change SELECT Top 1000 rows or EDIT Top 200 rows Default Values in SSMS*. Disponível em: https://www.se.com/us/en/faqs/FA386465/

> **Nota sobre as imagens:** todas as capturas de tela reproduzidas neste documento (itens 1 a 3 e 6 da lista acima) são hotlinks para os arquivos de imagem hospedados oficialmente pela Microsoft em learn.microsoft.com, extraídos diretamente dos tutoriais públicos indicados. Não foram encontradas capturas de tela oficiais e atuais da Microsoft especificamente para o Table Designer e para o Edit Top 200 Rows nas páginas de documentação vigentes — por isso essas duas seções permanecem apenas com texto descritivo.
