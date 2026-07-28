import csv
from datetime import datetime, timedelta

OUT = 'nfe_sample.csv'
ROWS = 5000
BASE_SQNFE = 100000

start_date = datetime(2020, 1, 1)

with open(OUT, 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f, delimiter=';')
    writer.writerow(['nrchaveacesso','vltotalnota','dtemissao','stnfe','sqnfe','tpnfe'])
    for i in range(1, ROWS+1):
        # nrchave: 44 chars -> 36 zeros + 8-digit counter
        nr = ('0'*36) + f"{i:08d}"
        # value: vary between 10.00 and 5000.00
        v = 10.0 + (i * 3.14159) % 4990.0
        v_str = f"{v:.2f}"
        # date cycles
        d = start_date + timedelta(days=(i % 2000))
        d_str = d.strftime('%Y-%m-%d')
        # status
        st = 'C' if (i % 100 == 0) else 'A'
        sq = BASE_SQNFE + i
        tp = 2 if (i % 7 == 0) else 1
        writer.writerow([nr, v_str, d_str, st, str(sq), str(tp)])

print(f"Wrote {ROWS} rows to {OUT}")
