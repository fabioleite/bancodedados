# Módulo 2 – SQL Server Administrativo

## Apostila para Auditores da Receita Estadual

---

## Apresentação do módulo

Este módulo apresenta os conceitos e ferramentas administrativas do SQL Server que são relevantes para quem usa o banco de dados como **ferramenta de análise fiscal**, não para quem o administra.

O público deste curso — auditores fiscais — não realizará instalação, configuração de servidores, tuning avançado ou rotinas de backup na prática: essas tarefas continuam sob responsabilidade do administrador de banco de dados (DBA). O objetivo aqui é outro: dar ao auditor **vocabulário técnico e senso crítico** para

- entender o que o DBA faz e por que isso afeta o seu trabalho (ex.: por que uma consulta está lenta, por que uma base foi restaurada, por que um job noturno atualiza os dados às 6h);
- usar utilitários administrativos de forma segura para inspecionar estrutura de dados, checar o andamento de cargas de informação e diagnosticar problemas simples em suas próprias consultas;
- reconhecer oportunidades de **automação** que a equipe de TI pode implementar para apoiar rotinas de fiscalização (importação de arquivos fiscais, atualização de bases analíticas, alertas de inconsistências).

Por isso, cada seção evita o aprofundamento operacional (comandos completos de configuração, parâmetros avançados de performance) e enfatiza **o que o auditor precisa reconhecer e para que serve**.

---

## Sumário

1. Atividades gerais de administração de bancos de dados no SQL Server
2. Gestão de recursos
3. Otimização de bancos de dados
4. Utilitários de gestão
5. Recuperação e backup
6. Automação de tarefas administrativas
7. Automações aplicadas à fiscalização: cenários práticos
8. Boas práticas e limites de atuação do auditor
9. Glossário
10. Referências

---

## 1. Atividades gerais de administração de bancos de dados no SQL Server

Um DBA de SQL Server trabalha, em linhas gerais, em quatro frentes: **instalar e configurar** a instância, **proteger** os dados (segurança e backup), **manter a performance** (otimização e monitoramento) e **automatizar** rotinas repetitivas. O auditor não executa essas tarefas, mas precisa reconhecer a estrutura que elas produzem, porque é dentro dela que ele vai trabalhar todos os dias.

### 1.1 Hierarquia de objetos que o auditor encontra

| Nível | O que é | Exemplo no contexto fiscal |
|---|---|---|
| **Instância** | Um "servidor" SQL Server instalado, com sua própria porta e configuração | Instância `SRV-FISCAL01` |
| **Banco de dados (database)** | Container lógico de dados, com seu próprio arquivo de dados e log | `DW_NOTAS_FISCAIS`, `SPED_CONTRIBUINTES` |
| **Esquema (schema)** | Agrupamento lógico de objetos dentro de um banco | `fiscal.notas`, `staging.importacao` |
| **Tabela / View** | Onde os dados residem ou são consultados | `fiscal.nota_fiscal_item`, `vw_apuracao_icms` |
| **Login / Usuário** | Identidade de acesso à instância e ao banco | Login `dominio\auditor.silva` |

Entender essa hierarquia ajuda o auditor a se localizar quando o DBA disponibiliza uma nova base ou quando surge um erro de permissão.

### 1.2 O que muda quando existe um DBA dedicado

Como a equipe de TI cuida da administração, o auditor deve saber **a quem e o que pedir**:

- solicitar acesso de leitura (`db_datareader`) a um banco ou schema específico, em vez de acesso administrativo;
- pedir a criação de uma *view* consolidada quando uma consulta analítica se repete com frequência entre a equipe;
- reportar lentidão de consulta com evidências (texto da consulta, horário, tempo de execução) em vez de tentar ajustar configurações do servidor;
- solicitar a restauração de uma base histórica para análise de período anterior (ver seção 5).

---

## 2. Gestão de recursos

Gestão de recursos é a área que trata de como o SQL Server distribui **memória, CPU, E/S de disco e conexões** entre os bancos e usuários. O DBA configura esses limites; o auditor não mexe neles, mas precisa entender os sintomas que eles produzem, porque muitos deles aparecem diretamente nas consultas analíticas do dia a dia.

### 2.1 Por que isso importa para o auditor

- **Concorrência**: se muitos auditores rodam consultas pesadas ao mesmo tempo sobre a mesma base transacional, todos sentem lentidão. Entender isso explica por que a TI costuma disponibilizar uma **base analítica separada** (réplica, data warehouse ou banco "somente leitura") para consultas de fiscalização, isolada do sistema que recebe as notas fiscais em tempo real.
- **Bloqueios (locks)**: quando uma consulta de leitura é executada sobre uma tabela que está sendo atualizada, ela pode "esperar" a atualização terminar. Saber que isso existe evita que o auditor pense que sua consulta "travou" sem motivo — na prática, ela está aguardando liberação de um recurso.
- **Resource Governor**: recurso do SQL Server que permite ao DBA limitar quanto de CPU/memória um grupo de usuários pode consumir. Se a TI aplicar essa política à conta usada pelos auditores, consultas muito pesadas podem ser automaticamente restringidas — é útil saber que esse limite pode existir antes de reportar "erro" no sistema.

### 2.2 Boas práticas do lado do auditor

Mesmo sem administrar recursos, o auditor pode escrever consultas mais leves:

- filtrar por período e por contribuinte o quanto antes na consulta (`WHERE` restritivo), em vez de trazer a base inteira para depois filtrar;
- evitar `SELECT *` em tabelas muito grandes quando poucas colunas são necessárias;
- preferir horários de menor concorrência (fora do processamento noturno de cargas) para consultas muito pesadas, quando possível.

---

## 3. Otimização de bancos de dados

Otimização, do ponto de vista do DBA, envolve índices, estatísticas, particionamento e ajuste de consultas. Para o auditor, o recorte relevante é **entender por que uma consulta está lenta e como formulá-la melhor** — não recriar índices ou reescrever o mecanismo de otimização.

### 3.1 Índices (conceito, não administração)

Um índice funciona como o índice remissivo de um livro: em vez de o SQL Server ler tabela inteira, ele consulta uma estrutura auxiliar ordenada para localizar as linhas diretamente. Para o auditor, o ponto prático é:

- consultas que filtram por uma coluna indexada (ex.: CNPJ, número de nota fiscal, data de emissão) tendem a ser muito mais rápidas;
- se uma consulta recorrente do time está lenta, vale reportar ao DBA quais colunas são usadas nos filtros (`WHERE`) e nos agrupamentos (`GROUP BY`/`JOIN`) — essa informação é o principal insumo para o DBA avaliar a criação de um índice.

### 3.2 Plano de execução (ferramenta de diagnóstico acessível ao auditor)

O **plano de execução** (*execution plan*) é a "receita" que o SQL Server monta para responder a uma consulta. No SSMS, é possível visualizá-lo (Ctrl+M antes de executar, ou o botão "Include Actual Execution Plan"). Ele mostra graficamente quais tabelas foram lidas, se um índice foi usado, e qual etapa consumiu mais tempo. Não é preciso dominar tuning para tirar valor disso: já ajuda **identificar visualmente o trecho mais custoso** de uma consulta antes de pedir apoio ao DBA.

### 3.3 Query Store

O **Query Store** é um recurso do SQL Server (disponível desde a versão 2016) que grava automaticamente o histórico de desempenho das consultas executadas em um banco — sem que o usuário precise fazer nada. Para o auditor, ele é útil porque:

- permite ver, pela interface do SSMS, quais consultas do time (ou próprias) mais consomem recursos ou pioraram de desempenho ao longo do tempo;
- não exige conhecimento de tuning: os relatórios prontos ("Top Resource Consuming Queries", "Regressed Queries") já vêm no menu do banco, em **Query Store**, no SSMS.

### 3.4 Estatísticas (conceito rápido)

O otimizador do SQL Server decide o plano de execução com base em estatísticas sobre a distribuição dos dados (quantos valores distintos existem em uma coluna, por exemplo). Quando uma base é atualizada em grande volume (ex.: carga mensal de SPED de milhares de contribuintes) e as consultas ficam lentas logo depois, isso costuma ser sintoma de estatísticas desatualizadas — outro caso em que vale reportar ao DBA em vez de tentar corrigir.

---

## 4. Utilitários de gestão

Esta seção apresenta as ferramentas que o auditor efetivamente pode instalar e usar no dia a dia — a maior parte do valor prático deste módulo está aqui.

### 4.1 SQL Server Management Studio (SSMS)

É a ferramenta administrativa "oficial" do SQL Server, gratuita, e continua sendo a mais completa para tarefas administrativas (jobs do SQL Server Agent, segurança, backup) e também para consultas analíticas. Para o auditor, os recursos mais úteis são:

- **Object Explorer**: navega pela estrutura das bases (schemas, tabelas, colunas, views) sem precisar de comandos.
- **Editor de consultas (New Query)**: escreve e executa T-SQL, exporta resultados para Excel/CSV.
- **Query Store e planos de execução**, descritos na seção 3.
- **Standard Reports** (clique com o botão direito sobre o banco → Reports): relatórios prontos sobre uso de disco, atividade recente e objetos do banco, úteis para entender rapidamente o "tamanho" e a "saúde" de uma base antes de consultá-la.

### 4.2 Visual Studio Code + extensão MSSQL

Desde 2025 a Microsoft descontinuou o **Azure Data Studio** (a ferramenta leve, multiplataforma, que havia sido lançada como alternativa ao SSMS) — o último lançamento foi em junho de 2025 e o suporte terminou em fevereiro de 2026. A recomendação oficial da Microsoft passou a ser a extensão **MSSQL para Visual Studio Code**, que herdou os principais recursos de consulta e navegação de dados do Azure Data Studio, em uma ferramenta multiplataforma (Windows, macOS, Linux) e mais leve que o SSMS. Para o auditor que só precisa consultar dados (sem tarefas administrativas como gestão de jobs do SQL Server Agent), essa é hoje a alternativa mais indicada ao SSMS.

### 4.3 sqlcmd e ferramentas de linha de comando

`sqlcmd` é o utilitário de linha de comando do SQL Server. Auditores não costumam precisar dele diretamente, mas é útil saber que ele existe porque muitas rotinas automatizadas de extração de dados (mencionadas na seção 6) são construídas sobre ele.

### 4.4 Outras ferramentas úteis para consumo de dados

- **Excel com conexão ODBC/OLE DB**: permite consultar o SQL Server diretamente de planilhas, útil para quem já trabalha em Excel na rotina de fiscalização.
- **Power BI**: conecta-se nativamente ao SQL Server e é frequentemente usado para dashboards de acompanhamento fiscal alimentados diretamente do banco.
- **SQL Server Reporting Services (SSRS)**: quando a TI publica relatórios corporativos padronizados (ex.: apuração mensal de ICMS por contribuinte), costuma ser através dessa ferramenta.

---

## 5. Recuperação e backup

O auditor não executa backups nem restaurações, mas dois conceitos aqui têm impacto direto no trabalho de fiscalização: **preservação de evidência** e **reconstituição de cenário histórico**.

### 5.1 Conceitos essenciais

- **Backup completo (full)**: cópia integral do banco em um momento específico.
- **Backup de log (transaction log)**: permite, combinado com o full, restaurar o banco para **um instante exato no passado** (*point-in-time restore*) — não apenas para o momento do último backup completo.
- **RPO (Recovery Point Objective)**: quanto de dado a organização aceita perder em caso de falha — define a frequência dos backups.
- **RTO (Recovery Time Objective)**: quanto tempo se aceita levar para restaurar o serviço.

### 5.2 Por que isso importa para a fiscalização

- **Reconstituir uma base em uma data específica**: se uma auditoria precisa analisar como os dados estavam registrados em uma data anterior a uma correção ou a uma fraude suspeita, o mecanismo técnico que viabiliza isso é justamente o backup de log combinado com *point-in-time restore*. Saber que essa capacidade existe permite ao auditor solicitar formalmente ao DBA a restauração de uma base "como ela estava em 15/03", por exemplo.
- **Cadeia de custódia de evidência digital**: um banco restaurado a partir de backup, com hash/checksum documentado, é frequentemente usado como evidência técnica em processos administrativos ou judiciais. O auditor não precisa operar o backup, mas deve saber pedir a documentação da restauração (data do backup de origem, responsável, hash) quando os dados restaurados forem usados como prova.
- **Retenção**: cada organização define por quanto tempo mantém backups históricos. Vale ao auditor confirmar com a TI a política de retenção antes de presumir que uma base de anos anteriores ainda pode ser restaurada.

---

## 6. Automação de tarefas administrativas

Automação, na perspectiva do DBA, significa programar o SQL Server para executar tarefas de manutenção sem intervenção manual (backups, reorganização de índices, atualização de estatísticas). O componente central é o **SQL Server Agent**.

### 6.1 SQL Server Agent (visão geral)

É o serviço do SQL Server responsável por executar **jobs** — conjuntos de passos (T-SQL, procedures, scripts, pacotes SSIS) — em horários ou eventos programados (agendamento por calendário, ou disparados por um evento). Cada job pode notificar por e-mail (via **Database Mail**) em caso de sucesso ou falha. O auditor não cria jobs, mas se beneficia diretamente deles: são jobs do SQL Server Agent que, por exemplo, atualizam a base analítica todas as noites com as notas fiscais recebidas no dia.

### 6.2 Outros mecanismos de automação relevantes

| Mecanismo | Para que serve | Relevância indireta para o auditor |
|---|---|---|
| **SSIS (SQL Server Integration Services)** | Automatiza processos de ETL (extrair, transformar, carregar dados) | Motor por trás da importação automática de arquivos XML de NF-e e SPED para a base analítica |
| **Alerts do SQL Server Agent** | Dispara ações (e-mail, job) quando uma condição é detectada | Pode ser configurado para avisar a equipe quando uma carga de dados falha ou atrasa |
| **Change Data Capture (CDC)** | Registra automaticamente todas as alterações feitas em uma tabela | Permite rastrear quem alterou um registro fiscal e quando, sem esforço manual |
| **Change Tracking** | Similar ao CDC, mas mais leve — registra apenas quais linhas mudaram | Útil para sincronizar apenas dados novos/alterados entre sistemas |
| **PowerShell + Agendador de tarefas do Windows / Agent** | Scripts de manutenção e extração fora do próprio SQL Server | Frequentemente usado para exportar relatórios periódicos automaticamente |

---

## 7. Automações aplicadas à fiscalização: cenários práticos

Esta é a seção mais diretamente aplicável ao dia a dia do auditor: como os mecanismos da seção 6 podem ser combinados para apoiar rotinas de fiscalização de documentos fiscais. O auditor não implementa nada disso sozinho — mas reconhecer essas possibilidades permite **pedir à TI, com precisão, a automação certa**.

1. **Importação automática de documentos fiscais eletrônicos.** Jobs do SQL Server Agent, acionando pacotes SSIS, podem ler diariamente (ou em tempo quase real) os arquivos XML de NF-e, NFC-e e CT-e recebidos e carregá-los em uma base estruturada, pronta para consulta em SQL — eliminando a necessidade de abrir XML manualmente.

2. **Consolidação de bases analíticas (data warehouse fiscal).** Um job noturno pode consolidar dados de múltiplos sistemas de origem (SEFAZ, ERP, SPED de contribuintes) em uma base única e padronizada, sobre a qual os auditores rodam suas consultas — evitando que cada análise precise cruzar manualmente fontes diferentes.

3. **Alertas automáticos de inconsistência.** Um job agendado pode rodar rotinas de checagem (ex.: notas fiscais com valores muito acima da média do CNAE, sequência de numeração com lacunas suspeitas, divergência entre valor declarado e valor apurado) e, ao encontrar ocorrências, disparar e-mail automático para a equipe de fiscalização via Database Mail — funcionando como uma triagem prévia antes da análise manual.

4. **Rastreamento de alterações em bases de contribuintes (CDC/Change Tracking).** Quando uma base recebe atualizações de terceiros (ex.: retificações enviadas pelo contribuinte), CDC permite reconstruir automaticamente o histórico de alterações — quem, quando e o que mudou — sem que o auditor precise comparar manualmente versões antigas e novas.

5. **Atualização programada de relatórios e dashboards.** Jobs podem disparar a atualização de relatórios do SSRS ou datasets do Power BI logo após a carga diária de dados, garantindo que o painel usado na reunião da manhã já reflita os documentos fiscais do dia anterior.

6. **Rotinas de amostragem periódica.** Um job pode, periodicamente, extrair automaticamente uma amostra estatística de notas fiscais (por setor, faixa de valor ou contribuinte) para compor a base de trabalho semanal de uma equipe de fiscalização, reduzindo o trabalho manual de seleção.

7. **Exportação automática de relatórios de apuração.** Scripts agendados podem gerar e enviar por e-mail, todo início de mês, planilhas consolidadas de apuração (ex.: ICMS por contribuinte) prontas para revisão, sem necessidade de execução manual de consultas repetitivas.

Em todos esses cenários, o papel do auditor é **especificar a regra de negócio** (o que checar, com que frequência, o que considerar "suspeito" ou "prioritário") — a implementação técnica da automação continua sendo do DBA/equipe de TI.

---

## 8. Boas práticas e limites de atuação do auditor

- Solicitar sempre acesso de **leitura** (nunca administrativo) às bases de trabalho.
- Preferir consultar **views ou bases analíticas** disponibilizadas pela TI em vez da base transacional de produção.
- Reportar lentidão ou erro com evidências (consulta, horário, mensagem de erro) em vez de tentar alterar configurações do servidor.
- Não solicitar nem tentar executar comandos administrativos (`BACKUP`, `RESTORE`, alteração de permissões, criação de jobs) — isso é atribuição do DBA.
- Ao usar dados restaurados de backup como evidência, sempre solicitar a documentação formal da restauração.
- Ao identificar uma consulta ou relatório repetitivo no time, propor à TI que seja automatizado (job ou view), em vez de repetir o trabalho manual toda semana.

---

## 9. Glossário

| Termo | Definição resumida |
|---|---|
| **Instância** | Instalação do motor SQL Server, com sua própria configuração e conjunto de bancos |
| **Schema** | Agrupamento lógico de objetos dentro de um banco de dados |
| **Índice** | Estrutura auxiliar que acelera a localização de linhas em uma tabela |
| **Plano de execução** | Sequência de operações que o SQL Server usa para responder a uma consulta |
| **Query Store** | Recurso que registra automaticamente o histórico de desempenho das consultas |
| **Resource Governor** | Mecanismo que limita CPU/memória por grupo de usuários |
| **Lock (bloqueio)** | Mecanismo de controle de concorrência entre consultas simultâneas |
| **RPO / RTO** | Métricas de perda de dado aceitável e tempo de restauração aceitável |
| **Point-in-time restore** | Restauração do banco para um instante exato do passado |
| **SQL Server Agent** | Serviço responsável por agendar e executar jobs automatizados |
| **Job** | Conjunto de passos executados automaticamente pelo SQL Server Agent |
| **SSIS** | Ferramenta de automação de processos de ETL (extração, transformação e carga) |
| **CDC (Change Data Capture)** | Recurso que registra automaticamente alterações feitas em uma tabela |
| **Database Mail** | Mecanismo de envio automático de e-mails a partir do SQL Server |

---

## 10. Referências

PETKOVIC, Dusan. **Microsoft SQL Server 2019: A Beginner's Guide**. 7. ed. New York: McGraw-Hill Education, 2020.

BRUSINO, Rudi. **Microsoft SQL Server 2019: A Beginner's Guide**. 6. ed. [S.l.]: McGraw-Hill Education, 2020.

Documentação oficial Microsoft Learn — SQL Server: Query Store, SQL Server Agent, Change Data Capture e migração do Azure Data Studio. Disponível em: https://learn.microsoft.com/pt-br/sql/.
