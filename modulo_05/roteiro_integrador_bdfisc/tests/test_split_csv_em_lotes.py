import csv
import sys
from pathlib import Path
import tempfile
import unittest

sys.path.append(str(Path(__file__).resolve().parents[1]))

from split_csv_em_lotes import split_csv_to_batches


class SplitCsvTests(unittest.TestCase):
    def test_split_csv_preserves_header_and_splits_by_row_count(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)
            input_path = tmp_path / "entrada.csv"
            output_dir = tmp_path / "partes"

            input_path.write_text(
                "codigo|nome\n1|Ana\n2|Bruno\n3|Carla\n",
                encoding="utf-8",
            )

            generated_files = split_csv_to_batches(
                input_csv=str(input_path),
                output_dir=str(output_dir),
                rows_per_file=2,
                delimiter="|",
            )

            self.assertEqual(len(generated_files), 2)

            with open(generated_files[0], "r", encoding="utf-8", newline="") as handle:
                first_file_rows = list(csv.reader(handle, delimiter="|"))

            with open(generated_files[1], "r", encoding="utf-8", newline="") as handle:
                second_file_rows = list(csv.reader(handle, delimiter="|"))

            self.assertEqual(first_file_rows, [["codigo", "nome"], ["1", "Ana"], ["2", "Bruno"]])
            self.assertEqual(second_file_rows, [["codigo", "nome"], ["3", "Carla"]])


if __name__ == "__main__":
    unittest.main()
