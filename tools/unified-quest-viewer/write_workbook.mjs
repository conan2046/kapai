import fs from 'node:fs/promises';
import path from 'node:path';
import { Workbook, SpreadsheetFile } from '@oai/artifact-tool';

const [inputPath, outputPath] = process.argv.slice(2);
if (!inputPath || !outputPath) throw new Error('Usage: write_workbook.mjs input.json output.xlsx');
const payload = JSON.parse(await fs.readFile(inputPath, 'utf8'));
const book = Workbook.create();
const letters = n => {
  let out = '';
  for (let x = n; x > 0; x = Math.floor((x - 1) / 26)) out = String.fromCharCode(65 + (x - 1) % 26) + out;
  return out;
};
for (const [table, columns] of Object.entries(payload.schema)) {
  const page = book.worksheets.add(table);
  const fields = columns.map(entry => entry[0]);
  const labels = columns.map(entry => entry[1]);
  const rows = payload.records[table] || [];
  const last = letters(fields.length);
  page.getRange(`A1:${last}2`).values = [labels, fields];
  page.getRange(`A1:${last}1`).format = {
    fill: '#21466F', font: { name: 'Microsoft YaHei', bold: true, color: '#FFFFFF', size: 11 },
    rowHeight: 27,
  };
  page.getRange(`A2:${last}2`).format = {
    fill: '#E9F1FA', font: { name: 'Arial', color: '#536780', size: 9 }, rowHeight: 22,
  };
  if (rows.length) {
    const matrix = rows.map(row => fields.map(key => {
      const value = row[key];
      if (value === undefined || value === null) return '';
      if (typeof value === 'object') return JSON.stringify(value);
      return value;
    }));
    page.getRange(`A3:${last}${rows.length + 2}`).values = matrix;
    page.getRange(`A3:${last}${rows.length + 2}`).format.font = { name: 'Microsoft YaHei', size: 10, color: '#23384F' };
  }
  page.getRange(`A1:${last}${Math.max(3, rows.length + 2)}`).format.columnWidth = 19;
  const widths = {
    event_key: 28, name: 24, trigger_point: 56, counter_mode: 25,
    description: 58, allowed_values: 42, comparison: 20, example: 18,
    reward_ref: 36, text: 58, note: 58, producer: 36,
    structure: 40, scope_reason: 38, node_id: 43, dialogue_phase: 25,
  };
  for (const [index, key] of fields.entries()) {
    if (widths[key]) page.getRange(`${letters(index + 1)}1:${letters(index + 1)}${Math.max(3, rows.length + 2)}`).format.columnWidth = widths[key];
  }
}
await fs.mkdir(path.dirname(outputPath), { recursive: true });
const xlsx = await SpreadsheetFile.exportXlsx(book);
await xlsx.save(outputPath);
process.stdout.write(JSON.stringify({ outputPath, tables: Object.keys(payload.schema).length }));
