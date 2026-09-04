from pathlib import Path
import csv

base = Path(r"c:\Users\fabio\projetos\bancodedados\modulo 04\dados")
base.mkdir(parents=True, exist_ok=True)

csv_path = base / "divergencia_nfe_efd_202401.csv"
cnpjs = [
    "12345678000199", "98765432000155", "11122233000144", "22233344000166",
    "33344455000177", "44455566000188", "55566677000199", "66677788000110",
    "77788899000121", "88899900000132",
]
ufs = ["SP", "RJ", "MG", "PR", "SC", "RS", "GO", "ES", "MT", "MS"]
cfops = ["6102", "6108", "5405", "5403", "5102", "6203", "6205", "5305"]

with csv_path.open("w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f, delimiter=';')
    writer.writerow([
        "periodo_apuracao", "cnpj", "uf_origem", "uf_destino", "cfop",
        "valor_documento", "valor_icms", "tipo_operacao", "numero_doc",
        "chave_acesso", "situacao_documento", "fonte_dado",
    ])
    for i in range(1, 10001):
        cnpj = cnpjs[(i - 1) % len(cnpjs)]
        uf_origem = ufs[(i - 1) % len(ufs)]
        cfop = cfops[(i - 1) % len(cfops)]
        valor_documento = round(1500 + ((i * 8.75) % 30000), 2)
        valor_icms = round(valor_documento * 0.18, 2)
        tipo_operacao = "SAIDA" if i % 2 == 0 else "ENTRADA"
        numero_doc = 50000 + i
        chave = f"352401{cnpj}{(i % 10000):05d}000000000{(i % 1000):03d}00000000"
        chave = chave[:44]
        situacao = "CANCELADA" if i % 5 == 0 else "AUTORIZADA"
        writer.writerow([
            "202401", cnpj, uf_origem, "PB", cfop,
            f"{valor_documento:.2f}", f"{valor_icms:.2f}", tipo_operacao,
            numero_doc, chave, situacao, "SISTEMA_EXTERNO",
        ])

with csv_path.open("r", encoding="utf-8") as f:
    registro_total = sum(1 for _ in f) - 1

print(f"Arquivo criado: {csv_path}")
print(f"Registros: {registro_total}")
print(f"Existe: {csv_path.exists()}")
