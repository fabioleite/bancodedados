# -*- coding: utf-8 -*-
"""
Gerador dos dados de exemplo do banco curso_integridade_fiscal.

Produz os scripts 02 a 05 (INSERT) com:
  - CNPJ e chave de acesso com digito verificador VALIDO;
  - volumes suficientes para os exercicios com HAVING (mais de 1.000 notas);
  - inconsistencias PLANTADAS de proposito, para que os cruzamentos de
    malha fiscal dos Modulos 9 e 10 tenham o que encontrar.

Execucao:  python3 gerar_dados.py
A semente e fixa: rodar de novo produz exatamente o mesmo banco.
"""
import os, random, datetime, textwrap, zlib

DIR  = os.path.dirname(os.path.abspath(__file__))
RNG  = random.Random(20260728)
ANO  = 2025

# =====================================================================
# 1. Utilitarios
# =====================================================================
def dv_cnpj(base12):
    """Digitos verificadores do CNPJ (modulo 11)."""
    def calc(nums, pesos):
        s = sum(int(n)*p for n, p in zip(nums, pesos))
        r = s % 11
        return '0' if r < 2 else str(11 - r)
    p1 = [5,4,3,2,9,8,7,6,5,4,3,2]
    p2 = [6,5,4,3,2,9,8,7,6,5,4,3,2]
    d1 = calc(base12, p1)
    d2 = calc(base12 + d1, p2)
    return d1 + d2

def novo_cnpj(rng):
    raiz = ''.join(str(rng.randint(0, 9)) for _ in range(8))
    base = raiz + '0001'
    return base + dv_cnpj(base)

def dv_chave(chave43):
    """Digito verificador da chave de acesso (modulo 11, pesos 2..9)."""
    peso, soma = 2, 0
    for c in reversed(chave43):
        soma += int(c) * peso
        peso = 2 if peso == 9 else peso + 1
    r = soma % 11
    return '0' if r in (0, 1) else str(11 - r)

def monta_chave(cuf, data, cnpj, modelo, serie, numero, tp_emis, cnf):
    b = '%s%02d%02d%s%s%03d%09d%s%08d' % (cuf, data.year % 100, data.month,
                                          cnpj, modelo, serie, numero, tp_emis, cnf)
    return b + dv_chave(b)

def lit(v):
    if v is None:                      return 'NULL'
    if isinstance(v, bool):            return '1' if v else '0'
    if isinstance(v, (int,)):          return str(v)
    if isinstance(v, float):           return ('%.4f' % v).rstrip('0').rstrip('.') or '0'
    if isinstance(v, datetime.date):   return "'%s'" % v.isoformat()
    return "'" + str(v).replace("'", "''") + "'"

def emitir(f, tabela, colunas, linhas, lote=400):
    f.write('PRINT \'  ... %s (%d linhas)\';\nGO\n\n' % (tabela, len(linhas)))
    for i in range(0, len(linhas), lote):
        bloco = linhas[i:i+lote]
        f.write('INSERT INTO %s\n    (%s)\nVALUES\n' % (tabela, ', '.join(colunas)))
        f.write(',\n'.join('    (' + ', '.join(lit(v) for v in ln) + ')' for ln in bloco))
        f.write(';\nGO\n\n')

def cabecalho(f, numero, titulo, descricao):
    f.write(textwrap.dedent("""\
        /* =====================================================================
           Curso de Banco de Dados Relacional aplicado a Fiscalizacao Tributaria
           Banco de exemplo: curso_integridade_fiscal
           Script %s - %s
           %s
           Gerado por gerar_dados.py (semente fixa: os dados sao sempre os mesmos)
           ===================================================================== */
        USE curso_integridade_fiscal;
        GO
        SET NOCOUNT ON;
        GO

        """) % (numero, titulo, descricao))

def rodape(f, numero):
    f.write("PRINT 'Script %s concluido.';\nGO\n" % numero)

def dinheiro(x):
    return round(x + 0.0, 2)

# =====================================================================
# 2. Municipios
# =====================================================================
MUNICIPIOS_PB = [
    ('2507507','JOAO PESSOA','1A GERENCIA REGIONAL'),
    ('2504009','CAMPINA GRANDE','2A GERENCIA REGIONAL'),
    ('2513703','PATOS','3A GERENCIA REGIONAL'),
    ('2504603','CAJAZEIRAS','4A GERENCIA REGIONAL'),
    ('2516805','SOUSA','4A GERENCIA REGIONAL'),
    ('2502250','BAYEUX','1A GERENCIA REGIONAL'),
    ('2509305','SANTA RITA','1A GERENCIA REGIONAL'),
    ('2504108','CABEDELO','1A GERENCIA REGIONAL'),
    ('2503209','GUARABIRA','5A GERENCIA REGIONAL'),
    ('2516409','SOLANEA','5A GERENCIA REGIONAL'),
    ('2500700','ALAGOA GRANDE','2A GERENCIA REGIONAL'),
    ('2502308','BELEM','5A GERENCIA REGIONAL'),
    ('2505501','CONDE','1A GERENCIA REGIONAL'),
    ('2506806','ESPERANCA','2A GERENCIA REGIONAL'),
    ('2509701','ITABAIANA','1A GERENCIA REGIONAL'),
    ('2510808','MAMANGUAPE','1A GERENCIA REGIONAL'),
    ('2512804','MONTEIRO','3A GERENCIA REGIONAL'),
    ('2513158','PEDRAS DE FOGO','1A GERENCIA REGIONAL'),
    ('2514800','POMBAL','4A GERENCIA REGIONAL'),
    ('2516003','SAPE','1A GERENCIA REGIONAL'),
    ('2500106','AGUA BRANCA','3A GERENCIA REGIONAL'),
    ('2511806','MARI','1A GERENCIA REGIONAL'),
    ('2512721','SAO BENTO','4A GERENCIA REGIONAL'),
    ('2515302','SANTA LUZIA','3A GERENCIA REGIONAL'),
    ('2504405','CATOLE DO ROCHA','4A GERENCIA REGIONAL'),
]
MUNICIPIOS_OUTRAS_UF = [
    ('2611606','RECIFE','PE'), ('2408102','NATAL','RN'), ('2704302','MACEIO','AL'),
    ('2927408','SALVADOR','BA'), ('2304400','FORTALEZA','CE'), ('3550308','SAO PAULO','SP'),
    ('3304557','RIO DE JANEIRO','RJ'), ('3106200','BELO HORIZONTE','MG'),
    ('4106902','CURITIBA','PR'), ('4314902','PORTO ALEGRE','RS'),
]

municipios = []
for i, (ibge, nome, regiao) in enumerate(MUNICIPIOS_PB, start=1):
    municipios.append([i, ibge, nome, 'PB', regiao])
for j, (ibge, nome, uf) in enumerate(MUNICIPIOS_OUTRAS_UF, start=len(MUNICIPIOS_PB)+1):
    municipios.append([j, ibge, nome, uf, None])       # regiao_fiscal NULL
MUN_PB = [m[0] for m in municipios if m[3] == 'PB']

# =====================================================================
# 3. Contribuintes
# =====================================================================
PREFIXOS = ['ALFA','BETA','GAMA','DELTA','EPSILON','ZETA','ETA','TETA','IOTA','KAPPA',
            'LAMBDA','OMEGA','SIGMA','PHI','ATLAS','AURORA','BOREAL','CAJU','DUNAS','ESTRELA',
            'FAROL','GIRASSOL','HORIZONTE','IMPERIAL','JANDAIA','LITORAL','MANGUE','NORDESTE',
            'ORQUIDEA','PLANALTO','QUIXABA','RECANTO','SERTAO','TAMBAU','UNIAO','VARZEA',
            'XIQUE','ZEBU','ARARA','BREJO','CARIRI','DIAMANTE','ESPINHEIRO','FLORESTA',
            'GAVIAO','IPE','JUAZEIRO','LUAR','MARACUJA','NOVA ERA','OASIS','PEDRA BRANCA',
            'RIACHO','SOLIMOES','TROPICAL','VITORIA','ARACAJU','BUZIOS','CORAL','DOURADO']
SUFIXOS = ['LTDA','S/A','ME','EIRELI','LTDA','COMERCIO LTDA']

# segmento: (rotulo, cnae, [ (ncm, descricao, preco_min, preco_max) ], cfops_saida)
SEGMENTOS = [
    ('DISTRIBUIDORA DE BEBIDAS', '4635499', [
        ('22030000','CERVEJA DE MALTE LATA 350ML',2.20,4.80),
        ('22021000','REFRIGERANTE PET 2L',3.50,8.90),
        ('22084000','AGUARDENTE DE CANA 1L',9.00,28.00),
        ('22011000','AGUA MINERAL SEM GAS 500ML',0.90,2.60),
        ('22042100','VINHO TINTO GARRAFA 750ML',18.00,120.00)], ['5102','6102','5405']),
    ('COMERCIO DE ALIMENTOS', '4639701', [
        ('19053100','BISCOITO DOCE PACOTE 400G',3.20,9.50),
        ('21069029','PREPARACAO ALIMENTICIA DIVERSOS',4.00,22.00),
        ('10063021','ARROZ BRANCO POLIDO 5KG',18.00,34.00),
        ('11010010','FARINHA DE TRIGO 1KG',3.60,7.90),
        ('04022110','LEITE EM PO INTEGRAL 400G',12.00,26.00)], ['5102','6102','5405']),
    ('ATACADISTA DE MATERIAL DE CONSTRUCAO', '4679604', [
        ('25232910','CIMENTO PORTLAND SACO 50KG',28.00,49.00),
        ('69072100','PISO CERAMICO 60X60 CAIXA',35.00,95.00),
        ('72142000','VERGALHAO CA-50 12MM BARRA',28.00,62.00),
        ('39172390','TUBO PVC 100MM BARRA 6M',45.00,130.00)], ['5102','6102','5101']),
    ('TRANSPORTES E LOGISTICA', '4930202', [
        ('27101259','OLEO DIESEL S10 LITRO',5.20,6.90),
        ('40111000','PNEU RADIAL ARO 15',280.00,760.00),
        ('84212300','FILTRO DE OLEO LUBRIFICANTE',22.00,85.00)], ['5102','6102','5949']),
    ('COMERCIO VAREJISTA DE CONFECCOES', '4781400', [
        ('61091000','CAMISETA ALGODAO ADULTO',12.00,49.00),
        ('62034200','CALCA JEANS MASCULINA',39.00,159.00),
        ('64029900','CALCADO SINTETICO PAR',29.00,189.00)], ['5102','5405','6108']),
    ('DROGARIA E PERFUMARIA', '4771701', [
        ('30049099','MEDICAMENTO USO HUMANO CAIXA',8.00,240.00),
        ('33051000','SHAMPOO 350ML',6.50,32.00),
        ('34011190','SABONETE EM BARRA 90G',1.80,6.40)], ['5405','5102','6102']),
    ('COMERCIO DE COMBUSTIVEIS', '4731800', [
        ('27101259','OLEO DIESEL S10 LITRO',5.20,6.90),
        ('27101249','GASOLINA COMUM LITRO',5.40,6.60),
        ('27111910','GAS LIQUEFEITO BOTIJAO 13KG',85.00,140.00)], ['5656','5102','6102']),
    ('INDUSTRIA DE MOVEIS', '3101200', [
        ('94036000','MESA DE MADEIRA 6 LUGARES',380.00,1900.00),
        ('94017900','CADEIRA ESTOFADA',95.00,540.00),
        ('44219900','ARTEFATO DE MADEIRA DIVERSOS',22.00,180.00)], ['5101','6101','5102']),
]

DESCRICAO_GENERICA = ['DIVERSOS','MERCADORIA','PROD','ITEM','VENDA DE MERCADORIA DIVERSOS']

contribuintes = []
cnpjs = set()
N_CONTRIB = 60
for i in range(1, N_CONTRIB + 1):
    while True:
        cnpj = novo_cnpj(RNG)
        if cnpj not in cnpjs:
            cnpjs.add(cnpj); break
    seg = SEGMENTOS[(i - 1) % len(SEGMENTOS)]
    razao = '%s %s %s' % (PREFIXOS[i-1], seg[0], RNG.choice(SUFIXOS))
    fantasia = None if RNG.random() < 0.35 else PREFIXOS[i-1]
    # 46 contribuintes na PB, 14 em outras UFs (destinatarios interestaduais)
    if i <= 46:
        id_mun = RNG.choice(MUN_PB)
    else:
        id_mun = RNG.choice([m[0] for m in municipios if m[3] != 'PB'])
    if   i <= 22: regime = 'NORMAL'
    elif i <= 40: regime = RNG.choice(['NORMAL','SIMPLES','SIMPLES'])
    elif i <= 52: regime = RNG.choice(['SIMPLES','MEI'])
    else:         regime = RNG.choice(['NORMAL','SIMPLES','ISENTO'])
    situacao = 'ATIVO'
    if i in (47, 55):  situacao = 'SUSPENSO'
    if i in (49, 58):  situacao = 'BAIXADO'
    if i in (51,):     situacao = 'INAPTO'
    inicio = datetime.date(RNG.randint(1998, 2023), RNG.randint(1, 12), RNG.randint(1, 28))
    faturamento = None if RNG.random() < 0.22 else dinheiro(RNG.choice([
        RNG.uniform(60_000, 340_000), RNG.uniform(400_000, 4_500_000),
        RNG.uniform(5_000_000, 70_000_000), RNG.uniform(80_000_000, 260_000_000)]))
    contribuintes.append([i, cnpj, razao, fantasia, id_mun, regime, situacao,
                          inicio, seg[1], faturamento])

SEG_DE = {c[0]: SEGMENTOS[(c[0]-1) % len(SEGMENTOS)] for c in contribuintes}
CNPJ_DE = {c[0]: c[1] for c in contribuintes}
REGIME_DE = {c[0]: c[5] for c in contribuintes}
SITUACAO_DE = {c[0]: c[6] for c in contribuintes}

# =====================================================================
# 4. Auditores fiscais (hierarquia de tres niveis)
# =====================================================================
NOMES = ['ANA BEATRIZ COSTA','CARLOS EDUARDO LIMA','MARIA DE FATIMA SOUZA','JOAO PAULO ALMEIDA',
         'RITA DE CASSIA NOBREGA','FRANCISCO ASSIS BARBOSA','LUCIANA MARQUES PEREIRA',
         'ROBERTO CARLOS FERREIRA','PATRICIA GOMES DANTAS','MARCOS ANTONIO VIEIRA',
         'JULIANA CAVALCANTI ROCHA','PAULO SERGIO MENDES','ADRIANA LOPES SANTIAGO',
         'FERNANDO HENRIQUE BRAGA','SANDRA REGINA TAVARES','ANTONIO CARLOS MOURA',
         'CLAUDIA HELENA FIGUEIREDO','RENATO AUGUSTO SILVEIRA','TEREZA CRISTINA MELO',
         'GILBERTO AMORIM DA SILVA']
REGIOES = ['1A GERENCIA REGIONAL','2A GERENCIA REGIONAL','3A GERENCIA REGIONAL',
           '4A GERENCIA REGIONAL','5A GERENCIA REGIONAL']
auditores = []
auditores.append([1001, NOMES[0], 'GERENTE', 'GERENCIA DE FISCALIZACAO',
                  datetime.date(2004, 3, 15), None])                      # topo
supervisores = []
for k in range(3):
    mat = 1010 + k
    supervisores.append(mat)
    auditores.append([mat, NOMES[1+k], 'SUPERVISOR', REGIOES[k],
                      datetime.date(2008 + k, RNG.randint(1,12), RNG.randint(1,28)), 1001])
for k in range(16):
    mat = 1020 + k
    auditores.append([mat, NOMES[4+k], 'AUDITOR', REGIOES[k % 5],
                      datetime.date(RNG.randint(2010, 2022), RNG.randint(1,12), RNG.randint(1,28)),
                      supervisores[k % 3]])
MAT_AUDITORES = [a[0] for a in auditores if a[2] == 'AUDITOR']

# =====================================================================
# 5. Pauta fiscal de referencia
# =====================================================================
referencia = {}
for seg in SEGMENTOS:
    for ncm, desc, vmin, vmax in seg[2]:
        referencia[ncm] = [ncm, desc, round(vmin*0.85, 4), round(vmax*1.15, 4)]
referencia = sorted(referencia.values())

# =====================================================================
# 6. NF-e e itens
# =====================================================================
# Volume por emitente: distribuicao de Pareto, para que os exercicios com
# HAVING COUNT(*) > 500 e > 1000 tenham resultado.
VOLUME = {}
for c in contribuintes:
    i = c[0]
    if   i in (1, 2, 3):  VOLUME[i] = {1: 1500, 2: 1320, 3: 1180}[i]
    elif i <= 7:          VOLUME[i] = RNG.randint(560, 820)
    elif i <= 10:         VOLUME[i] = RNG.randint(240, 520)
    elif i <= 22:         VOLUME[i] = RNG.randint(80, 210)
    elif i <= 46:         VOLUME[i] = RNG.randint(12, 90)
    else:                 VOLUME[i] = RNG.randint(0, 18)
    if i in (4, 12):      VOLUME[i] = RNG.randint(260, 340)   # alto cancelamento
    if c[6] == 'BAIXADO': VOLUME[i] = 0

CARGA_BAIXA   = {5, 17}          # muitos itens isentos -> carga efetiva < 4%
CANCELA_MUITO = {12, 4}          # percentual de cancelamento acima de 15%
PARES_CIRCULARES = [(8, 19), (14, 27), (23, 31)]
UF_DE = {m[0]: m[3] for m in municipios}
MUN_DE = {c[0]: c[4] for c in contribuintes}
VAREJO = {'COMERCIO VAREJISTA DE CONFECCOES', 'DROGARIA E PERFUMARIA', 'COMERCIO DE COMBUSTIVEIS'}

nfe, nfe_item = [], []
id_nfe = id_item = 0
numeracao = {}
chaves_usadas = set()

def nova_nota(emit, dest, data, tipo='1', situacao=None, serie=1):
    """Cria cabecalho + itens e devolve o id da nota."""
    global id_nfe, id_item
    id_nfe += 1
    numeracao[(emit, serie)] = numeracao.get((emit, serie), 0) + 1
    numero = numeracao[(emit, serie)]
    if situacao is None:
        r = RNG.random()
        if emit in CANCELA_MUITO:
            situacao = 'CANCELADA' if r < 0.22 else ('DENEGADA' if r < 0.25 else 'AUTORIZADA')
        else:
            situacao = ('CANCELADA' if r < 0.045 else
                        'DENEGADA'  if r < 0.058 else
                        'INUTILIZADA' if r < 0.063 else 'AUTORIZADA')
    while True:
        chave = monta_chave('25', data, CNPJ_DE[emit], '55', serie, numero,
                            '1', RNG.randint(0, 99999999))
        if chave not in chaves_usadas:
            chaves_usadas.add(chave); break
    seg = SEG_DE[emit]
    interestadual = dest is not None and UF_DE[MUN_DE[dest]] != 'PB'
    total = icms_total = 0.0
    n_itens = RNG.choice([1,1,2,2,2,3,3,4,5,6])
    for k in range(1, n_itens + 1):
        ncm, desc, vmin, vmax = RNG.choice(seg[2])
        cfop = RNG.choice([c for c in seg[3] if c.startswith('6')] if interestadual
                          else [c for c in seg[3] if c.startswith('5')] or seg[3])
        if tipo == '0':
            cfop = '1102' if not interestadual else '2102'
        qtd  = float(RNG.choice([1,2,3,5,6,10,12,20,24,30,50,100,120,200]))
        vun  = round(RNG.uniform(vmin, vmax), 4)
        vtot = dinheiro(qtd * vun)
        isento = (emit in CARGA_BAIXA and RNG.random() < 0.90) or RNG.random() < 0.06
        if isento:
            cst, aliq, vicms = '040', None, 0.0
        elif REGIME_DE[emit] in ('SIMPLES','MEI'):
            cst  = '101'
            aliq = round(RNG.choice([1.25, 1.86, 2.33, 3.02]), 2)
            vicms = dinheiro(vtot * aliq / 100)
        else:
            cst  = '000'
            aliq = 12.00 if interestadual else RNG.choice([18.00, 18.00, 18.00, 20.00, 25.00])
            vicms = dinheiro(vtot * aliq / 100)
        descricao = RNG.choice(DESCRICAO_GENERICA) if RNG.random() < 0.012 else desc
        id_item += 1
        nfe_item.append([id_item, id_nfe, k, 'PRD-%05d' % (zlib.crc32(('%s-%d' % (ncm, emit)).encode()) % 99999),
                         descricao, ncm, cfop, cst, qtd, vun, vtot, aliq, vicms])
        total += vtot; icms_total += vicms
    nfe.append([id_nfe, chave, numero, serie, data, emit, dest, tipo,
                dinheiro(total), dinheiro(icms_total), situacao])
    return id_nfe

def data_aleatoria(mes=None):
    m = mes or RNG.randint(1, 12)
    d = RNG.randint(1, [31,28,31,30,31,30,31,31,30,31,30,31][m-1])
    return datetime.date(ANO, m, d)

destinatarios_possiveis = [c[0] for c in contribuintes if c[6] != 'BAIXADO']
# Alguns contribuintes NUNCA figuram como destinatarios (exercicio E3)
NUNCA_DESTINATARIO = {41, 44, 48, 52, 57}
destinatarios_possiveis = [i for i in destinatarios_possiveis if i not in NUNCA_DESTINATARIO]

for c in contribuintes:
    emit = c[0]
    for _ in range(VOLUME[emit]):
        tipo = '0' if RNG.random() < 0.12 else '1'
        if SEG_DE[emit][0] in VAREJO and tipo == '1' and RNG.random() < 0.38:
            dest = None                                   # consumidor nao identificado
        else:
            dest = RNG.choice([d for d in destinatarios_possiveis if d != emit])
        nova_nota(emit, dest, data_aleatoria(), tipo)

# --- operacoes circulares (indicio de simulacao) ----------------------
for a, b in PARES_CIRCULARES:
    base = data_aleatoria(RNG.randint(1, 10))
    for k in range(4):
        nova_nota(a, b, base + datetime.timedelta(days=RNG.randint(0, 25)), '1', 'AUTORIZADA')
        nova_nota(b, a, base + datetime.timedelta(days=RNG.randint(0, 25)), '1', 'AUTORIZADA')

# --- divergencia entre a soma dos itens e o total do cabecalho --------
IDX = {n[0]: n for n in nfe}
autorizadas = [n[0] for n in nfe if n[10] == 'AUTORIZADA' and n[7] == '1']
graudas = [i for i in autorizadas if IDX[i][8] > 3000]
for idn in RNG.sample(graudas, 15):
    IDX[idn][8] = dinheiro(IDX[idn][8] + RNG.choice([-1, 1]) * RNG.uniform(50, 900))

# --- chaves de acesso internamente inconsistentes ---------------------
def rechavear(chave44, cnpj=None, aamm=None):
    b = chave44[:43]
    if cnpj: b = b[:6] + cnpj + b[20:]
    if aamm: b = b[:2] + aamm + b[6:]
    return b + dv_chave(b)

alvos = RNG.sample(autorizadas, 13)
for k, idn in enumerate(alvos):
    n = IDX[idn]
    if k < 6:                                    # CNPJ da chave <> CNPJ do emitente
        outro = RNG.choice([c[1] for c in contribuintes if c[0] != n[5]])
        nova = rechavear(n[1], cnpj=outro)
    elif k < 11:                                 # periodo da chave <> data de emissao
        mes = 1 + (n[4].month % 12)
        nova = rechavear(n[1], aamm='%02d%02d' % (ANO % 100, mes))
    else:                                        # comprimento invalido (43 posicoes)
        nova = n[1][:43]
    if nova not in chaves_usadas:
        chaves_usadas.discard(n[1]); chaves_usadas.add(nova); n[1] = nova

# =====================================================================
# 7. EFD - registros C100 e C170
# =====================================================================
PERIODOS = ['%d%02d' % (ANO, m) for m in range(1, 13)]
DECLARANTES = [c[0] for c in contribuintes if c[5] == 'NORMAL' and c[6] != 'BAIXADO']
_cand = [c[0] for c in contribuintes
         if c[5] == 'NORMAL' and c[6] == 'ATIVO' and VOLUME.get(c[0], 0) > 0]
OMISSOS_202501 = set(RNG.sample(_cand, 8))   # ativos do regime normal que nao entregaram 202501

itens_por_nota = {}
for it in nfe_item:
    itens_por_nota.setdefault(it[1], []).append(it)

efd_c100, efd_c170 = [], []
id_c100 = id_c170 = 0
divergencias_valor = divergencias_item = 0

def grava_c100(contrib, periodo, ind_oper, cod_sit, num, serie, chave, data, vdoc, vicms, itens):
    global id_c100, id_c170
    id_c100 += 1
    efd_c100.append([id_c100, contrib, periodo, ind_oper, cod_sit, num,
                     str(serie), chave, data, dinheiro(vdoc), dinheiro(vicms)])
    for k, it in enumerate(itens, start=1):
        id_c170 += 1
        efd_c170.append([id_c170, id_c100, k, it['cod'], it['desc'], it['ncm'], it['cfop'],
                         it['cst'], it['qtd'], dinheiro(it['valor']), it['aliq'],
                         dinheiro(it['icms'])])

for contrib in DECLARANTES:
    for periodo in PERIODOS:
        if periodo == '202501' and contrib in OMISSOS_202501:
            continue
        if RNG.random() < 0.04:                 # periodo nao entregue
            continue
        mes = int(periodo[4:])
        notas = [n for n in nfe
                 if n[5] == contrib and n[4].month == mes and n[7] == '1'
                 and n[10] in ('AUTORIZADA', 'CANCELADA')]
        for n in notas:
            regular = n[10] == 'AUTORIZADA'
            if regular and RNG.random() < 0.075:   # OMISSAO de escrituracao
                continue
            vdoc, vicms = n[8], n[9]
            if regular and RNG.random() < 0.022:   # divergencia de valor
                vdoc  = dinheiro(vdoc * RNG.uniform(0.72, 0.95))
                vicms = dinheiro(vicms * RNG.uniform(0.60, 0.92))
                divergencias_valor += 1
            itens = []
            for it in itens_por_nota.get(n[0], []):
                d = {'cod': it[3], 'desc': None if RNG.random() < 0.7 else it[4],
                     'ncm': it[5], 'cfop': it[6], 'cst': it[7], 'qtd': it[8],
                     'valor': it[10], 'aliq': it[11], 'icms': it[12]}
                if regular and RNG.random() < 0.02:      # divergencia de item
                    escolha = RNG.randint(1, 4)
                    if   escolha == 1: d['ncm']  = RNG.choice([r[0] for r in referencia])
                    elif escolha == 2: d['cfop'] = RNG.choice(['5102','5405','6102','5949'])
                    elif escolha == 3: d['aliq'] = None if d['aliq'] else 18.00
                    else:              d['valor'] = dinheiro(d['valor'] * RNG.uniform(0.6, 0.9))
                    divergencias_item += 1
                itens.append(d)
            grava_c100(contrib, periodo, '1', '00' if regular else '02',
                       n[2], n[3], n[1], n[4], vdoc, vicms, itens)
        # entradas escrituradas (subconjunto das notas recebidas)
        recebidas = [n for n in nfe if n[6] == contrib and n[4].month == mes
                     and n[10] == 'AUTORIZADA' and n[7] == '1']
        for n in RNG.sample(recebidas, min(len(recebidas), RNG.randint(0, 6))):
            itens = [{'cod': it[3], 'desc': None, 'ncm': it[5], 'cfop': '1102',
                      'cst': it[7], 'qtd': it[8], 'valor': it[10], 'aliq': it[11],
                      'icms': it[12]} for it in itens_por_nota.get(n[0], [])]
            grava_c100(contrib, periodo, '0', '00', n[2], n[3], n[1], n[4], n[8], n[9], itens)

# --- C100 sem NF-e correspondente (documento inexistente ou de outra UF)
fantasmas = 0
for _ in range(38):
    contrib = RNG.choice(DECLARANTES)
    periodo = RNG.choice(PERIODOS)
    while periodo == '202501' and contrib in OMISSOS_202501:
        periodo = RNG.choice(PERIODOS)
    data = datetime.date(ANO, int(periodo[4:]), RNG.randint(1, 28))
    cnpj_estranho = novo_cnpj(RNG)
    chave = monta_chave(RNG.choice(['26','24','27','35']), data, cnpj_estranho, '55',
                        1, RNG.randint(1, 999999), '1', RNG.randint(0, 99999999))
    if chave in chaves_usadas:
        continue
    vdoc = dinheiro(RNG.uniform(1_500, 90_000))
    itens = [{'cod': 'PRD-99999', 'desc': None, 'ncm': RNG.choice([r[0] for r in referencia]),
              'cfop': '1102', 'cst': '000', 'qtd': float(RNG.randint(1, 40)),
              'valor': dinheiro(vdoc), 'aliq': 18.00, 'icms': dinheiro(vdoc*0.18)}]
    grava_c100(contrib, periodo, '0', '00', RNG.randint(1, 999999), 1, chave, data,
               vdoc, dinheiro(vdoc*0.18), itens)
    fantasmas += 1

# --- documentos nao eletronicos (chave_acesso NULL) -------------------
for _ in range(25):
    contrib = RNG.choice(DECLARANTES)
    periodo = RNG.choice(PERIODOS)
    while periodo == '202501' and contrib in OMISSOS_202501:
        periodo = RNG.choice(PERIODOS)
    data = datetime.date(ANO, int(periodo[4:]), RNG.randint(1, 28))
    vdoc = dinheiro(RNG.uniform(200, 9_000))
    grava_c100(contrib, periodo, '0', '00', RNG.randint(1, 99999), 1, None, data,
               vdoc, dinheiro(vdoc*0.12), [])

# =====================================================================
# 8. Ordens de servico e autos de infracao
# =====================================================================
ordem_servico, auto_infracao = [], []
DISPOSITIVOS = [
    'Art. 158, V, do RICMS/PB - falta de escrituracao de saidas',
    'Art. 158, VII, do RICMS/PB - divergencia entre EFD e NF-e',
    'Art. 160, II, do RICMS/PB - credito indevido de ICMS',
    'Art. 155, I, do RICMS/PB - omissao de receitas',
    'Art. 162, IV, do RICMS/PB - documento inidoneo',
]
SIT_AUTO = ['LAVRADO','IMPUGNADO','JULGADO PROCEDENTE','JULGADO IMPROCEDENTE',
            'PAGO','INSCRITO DIVIDA ATIVA']
id_os = id_auto = 0
alvos_os = [c[0] for c in contribuintes if VOLUME[c[0]] > 0]
for k in range(150):
    id_os += 1
    contrib = RNG.choice(alvos_os)
    aud = RNG.choice(MAT_AUDITORES)
    tipo = RNG.choice(['MALHA FISCAL','MALHA FISCAL','AUDITORIA PLENA','MONITORAMENTO','DILIGENCIA'])
    if RNG.random() < 0.70:
        abertura = data_aleatoria(RNG.randint(1, 11))
    else:
        abertura = datetime.date(ANO + 1, RNG.randint(1, 6), RNG.randint(1, 28))
    r = RNG.random()
    if r < 0.55:
        conclusao = abertura + datetime.timedelta(days=RNG.randint(12, 210))
        if conclusao > datetime.date(ANO + 1, 6, 30):
            conclusao = datetime.date(ANO + 1, 6, 30)
        situacao = 'CONCLUIDA'
    elif r < 0.80:
        conclusao, situacao = None, 'EM ANDAMENTO'
    elif r < 0.93:
        conclusao, situacao = None, 'ABERTA'
    else:
        conclusao, situacao = abertura + datetime.timedelta(days=RNG.randint(5, 60)), 'CANCELADA'
    ordem_servico.append([id_os, 'OS-%d-%05d' % (ANO, id_os), contrib, aud, tipo,
                          abertura, conclusao, situacao])
    if situacao == 'CONCLUIDA' and RNG.random() < 0.72:
        for _ in range(RNG.choice([1,1,1,2])):
            id_auto += 1
            principal = dinheiro(RNG.choice([RNG.uniform(2_000, 40_000),
                                             RNG.uniform(40_000, 300_000),
                                             RNG.uniform(300_000, 2_800_000)]))
            auto_infracao.append([id_auto, 'AI-%d-%05d' % (ANO, id_auto), id_os, contrib,
                                  conclusao, RNG.choice(DISPOSITIVOS), principal,
                                  dinheiro(principal * RNG.choice([0.5, 0.75, 1.0])),
                                  RNG.choice(SIT_AUTO)])

# =====================================================================
# 9. Escrita dos scripts
# =====================================================================
with open(os.path.join(DIR, '02_inserir_cadastros.sql'), 'w', encoding='utf-8') as f:
    cabecalho(f, '02', 'Dados de cadastro',
              'Municipios, contribuintes, auditores fiscais e pauta de referencia.')
    emitir(f, 'dbo.municipio', ['id_municipio','cod_ibge','nome','uf','regiao_fiscal'], municipios)
    emitir(f, 'dbo.auditor_fiscal', ['matricula','nome','cargo','regiao_fiscal',
                                     'data_admissao','matricula_supervisor'], auditores, lote=50)
    emitir(f, 'dbo.contribuinte', ['id_contribuinte','cnpj','razao_social','nome_fantasia',
                                   'id_municipio','regime_tributario','situacao_cadastral',
                                   'data_inicio_atividade','cnae_principal','faturamento_declarado'],
           contribuintes, lote=60)
    emitir(f, 'dbo.referencia_preco', ['ncm','descricao','valor_min','valor_max'], referencia)
    rodape(f, '02')

with open(os.path.join(DIR, '03_inserir_nfe.sql'), 'w', encoding='utf-8') as f:
    cabecalho(f, '03', 'Documentos fiscais eletronicos',
              'Cabecalhos (nfe) e itens (nfe_item) do exercicio de %d.' % ANO)
    emitir(f, 'dbo.nfe', ['id_nfe','chave_acesso','numero','serie','data_emissao','id_emitente',
                          'id_destinatario','tipo_operacao','valor_total','valor_icms','situacao'], nfe)
    emitir(f, 'dbo.nfe_item', ['id_item','id_nfe','num_item','cod_produto','descricao','ncm','cfop',
                               'cst_icms','quantidade','valor_unitario','valor_total_item',
                               'aliquota_icms','valor_icms_item'], nfe_item, lote=300)
    rodape(f, '03')

with open(os.path.join(DIR, '04_inserir_efd.sql'), 'w', encoding='utf-8') as f:
    cabecalho(f, '04', 'Escrituracao Fiscal Digital',
              'Registros C100 (documentos) e C170 (itens) declarados pelos contribuintes.')
    emitir(f, 'dbo.efd_c100', ['id_c100','id_contribuinte','periodo_apuracao','ind_oper',
                               'cod_situacao','num_doc','serie','chave_acesso','data_emissao',
                               'valor_documento','valor_icms'], efd_c100)
    emitir(f, 'dbo.efd_c170', ['id_c170','id_c100','num_item','cod_item','descricao_complementar',
                               'ncm','cfop','cst_icms','quantidade','valor_item','aliquota_icms',
                               'valor_icms_item'], efd_c170, lote=300)
    rodape(f, '04')

with open(os.path.join(DIR, '05_inserir_fiscalizacao.sql'), 'w', encoding='utf-8') as f:
    cabecalho(f, '05', 'Atividade de fiscalizacao',
              'Ordens de servico e autos de infracao.')
    emitir(f, 'dbo.ordem_servico', ['id_os','numero_os','id_contribuinte','matricula_auditor',
                                    'tipo_fiscalizacao','data_abertura','data_conclusao','situacao'],
           ordem_servico, lote=100)
    emitir(f, 'dbo.auto_infracao', ['id_auto','numero_auto','id_os','id_contribuinte','data_lavratura',
                                    'dispositivo_legal','valor_principal','valor_multa','situacao'],
           auto_infracao, lote=100)
    rodape(f, '05')

# =====================================================================
# 10. Resumo no console
# =====================================================================
print('municipio ............ %6d' % len(municipios))
print('contribuinte ......... %6d' % len(contribuintes))
print('auditor_fiscal ....... %6d' % len(auditores))
print('referencia_preco ..... %6d' % len(referencia))
print('nfe .................. %6d' % len(nfe))
print('nfe_item ............. %6d' % len(nfe_item))
print('efd_c100 ............. %6d' % len(efd_c100))
print('efd_c170 ............. %6d' % len(efd_c170))
print('ordem_servico ........ %6d' % len(ordem_servico))
print('auto_infracao ........ %6d' % len(auto_infracao))
print('-- inconsistencias plantadas --')
print('C100 sem NF-e ........ %6d' % fantasmas)
print('divergencia de valor . %6d' % divergencias_valor)
print('divergencia de item .. %6d' % divergencias_item)
