from pathlib import Path
import csv

base_dir = Path(__file__).resolve().parent / "dados"
base_dir.mkdir(parents=True, exist_ok=True)

cfop_path = base_dir / "cfop_referencia_externa.csv"
csv_path = base_dir / "divergencia_nfe_efd_202401.csv"

cfop_rows = [
    ["cfop", "descricao_cfop", "tipo_operacao", "natureza", "aliquota_ref"],
    ["6102", "Venda de mercadoria para fora do estado", "SAIDA", "INTERESTADUAL", "18.00"],
    ["6108", "Venda de mercadoria para consumidor final", "SAIDA", "INTERESTADUAL", "18.00"],
    ["5405", "Compra de mercadoria para industrializacao", "ENTRADA", "INTERESTADUAL", "12.00"],
    ["5403", "Compra de mercadoria para revenda", "ENTRADA", "INTERESTADUAL", "12.00"],
    ["5102", "Operacao de comercio exterior", "SAIDA", "INTERNACIONAL", "0.00"],
    ["6203", "Prestacao de servico para outra UF", "SAIDA", "INTERESTADUAL", "18.00"],
    ["6205", "Prestacao de servico para consumidor local", "SAIDA", "INTERESTADUAL", "18.00"],
    ["5305", "Compra de servico interestadual", "ENTRADA", "INTERESTADUAL", "12.00"],
]
with cfop_path.open("w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f, delimiter=";")
    writer.writerows(cfop_rows)

cnpjs = [
    "12345678000199", "98765432000155", "11122233000144", "22233344000166",
    "33344455000177", "44455566000188", "55566677000199", "66677788000110",
    "77788899000121", "88899900000132",
]
ufs = ["SP", "RJ", "MG", "PR", "SC", "RS", "GO", "ES", "MT", "MS"]
cfops = ["6102", "6108", "5405", "5403", "5102", "6203", "6205", "5305"]

with csv_path.open("w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f, delimiter=";")
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
        # Mantém a chave em 44 caracteres para ficar compatível com o padrão NF-e
        # e evitar truncamento no BULK INSERT do roteiro.
        chave = (chave[:44]).ljust(44, "0")
        situacao = "CANCELADA" if i % 5 == 0 else "AUTORIZADA"
        writer.writerow([
            "202401", cnpj, uf_origem, "PB", cfop,
            f"{valor_documento:.2f}", f"{valor_icms:.2f}", tipo_operacao,
            numero_doc, chave, situacao, "SISTEMA_EXTERNO",
        ])

print(f"Arquivo gerado: {csv_path} ({sum(1 for _ in csv_path.open('r', encoding='utf-8')) - 1} registros)")
print(f"Arquivo CFOP gerado: {cfop_path} ({sum(1 for _ in cfop_path.open('r', encoding='utf-8')) - 1} registros)")
