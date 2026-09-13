import argparse
import csv
import io
import os
import re
import zipfile
import xml.etree.ElementTree as ET


MAIN_NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
NS = {"x": MAIN_NS}


def column_index(cell_reference):
    letters = re.match(r"[A-Z]+", cell_reference).group(0)
    value = 0
    for letter in letters:
        value = value * 26 + ord(letter) - ord("A") + 1
    return value - 1


def shared_strings(archive):
    root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
    values = []
    for item in root.findall("x:si", NS):
        values.append("".join(node.text or "" for node in item.iter(f"{{{MAIN_NS}}}t")))
    return values


def read_rows(workbook_path):
    with zipfile.ZipFile(workbook_path) as archive:
        strings = shared_strings(archive)
        root = ET.fromstring(archive.read("xl/worksheets/sheet1.xml"))
        rows = []
        for row in root.findall(".//x:sheetData/x:row", NS):
            row_number = int(row.attrib["r"])
            if row_number < 5:
                continue
            values = [""] * 8
            for cell in row.findall("x:c", NS):
                index = column_index(cell.attrib["r"])
                if index >= len(values):
                    continue
                value = cell.find("x:v", NS)
                raw = "" if value is None else value.text or ""
                if cell.attrib.get("t") == "s":
                    raw = strings[int(raw)]
                values[index] = raw
            if any(values):
                rows.append(values)
        return rows


def build_csv(rows):
    output = io.StringIO(newline="")
    writer = csv.writer(output, lineterminator="\n")
    writer.writerow(["id", "question", "answer1", "answer2", "answer3", "answer4"])
    for row in rows:
        writer.writerow([int(float(row[0])), row[3], row[4], row[5], row[6], row[7]])
    return output.getvalue()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--workbook", required=True)
    parser.add_argument("--csv", required=True)
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()

    workbook_path = os.path.abspath(args.workbook)
    csv_path = os.path.abspath(args.csv)
    if not os.path.isfile(workbook_path):
        raise RuntimeError(f"Question workbook is missing: {workbook_path}")
    rows = read_rows(workbook_path)
    if len(rows) != 38:
        raise RuntimeError(f"Question workbook must contain 38 data rows, got {len(rows)}")
    generated = build_csv(rows)

    if args.validate_only:
        if not os.path.isfile(csv_path):
            raise RuntimeError(f"Question CSV is missing: {csv_path}")
        with open(csv_path, "r", encoding="utf-8-sig", newline="") as stream:
            current = stream.read().replace("\r\n", "\n")
        if current != generated:
            raise RuntimeError("question.csv is stale. Import the planning workbook again.")
        print(f"Question workbook source valid: rows={len(rows)}")
        return

    os.makedirs(os.path.dirname(csv_path), exist_ok=True)
    with open(csv_path, "w", encoding="utf-8-sig", newline="") as stream:
        stream.write(generated)
    print(f"Question workbook imported: rows={len(rows)}")


if __name__ == "__main__":
    main()
