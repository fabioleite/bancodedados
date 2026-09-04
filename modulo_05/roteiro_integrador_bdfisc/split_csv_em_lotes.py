import csv
from pathlib import Path
from typing import List


def split_csv_to_batches(
    input_csv: str,
    output_dir: str,
    rows_per_file: int = 10000,
    delimiter: str = ",",
) -> List[str]:
    source_path = Path(input_csv)
    target_dir = Path(output_dir)
    target_dir.mkdir(parents=True, exist_ok=True)

    if not source_path.exists():
        raise FileNotFoundError(f"Input file not found: {source_path}")

    generated_files: List[str] = []

    with source_path.open("r", encoding="utf-8-sig", newline="") as source_handle:
        reader = csv.reader(source_handle, delimiter=delimiter)

        header = next(reader, None)
        if header is None:
            raise ValueError(f"{source_path} is empty.")

        batch_index = 0
        current_batch = []

        def flush_batch() -> None:
            nonlocal batch_index, current_batch

            if not current_batch:
                return

            batch_index += 1
            output_path = target_dir / f"abcfarma_{batch_index:04d}.csv"
            with output_path.open("w", encoding="utf-8", newline="") as out_handle:
                writer = csv.writer(out_handle, delimiter=delimiter)
                writer.writerow(header)
                writer.writerows(current_batch)

            generated_files.append(str(output_path))
            current_batch = []

        for row in reader:
            current_batch.append(row)

            if len(current_batch) >= rows_per_file:
                flush_batch()

        flush_batch()

    return generated_files


if __name__ == "__main__":
    import sys

    if len(sys.argv) != 3:
        print("Uso: python split_csv_em_lotes.py <arquivo_entrada.csv> <pasta_saida>")
        raise SystemExit(1)

    files = split_csv_to_batches(sys.argv[1], sys.argv[2])
    print("Arquivos gerados:")
    for path in files:
        print(path)
