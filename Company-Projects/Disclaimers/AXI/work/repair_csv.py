import re, csv, collections
from openpyxl import Workbook

src = 'AXA_IM_disclaimers_with_ISIN.csv'
out_csv = 'AXA_IM_disclaimers_with_ISIN_fixed.csv'
out_xlsx = 'AXA_IM_disclaimers_with_ISIN.xlsx'
f = r'("[^"]*"|)'
pat = re.compile('^' + ','.join([f] * 5) + r',(.*),' + ','.join([f] * 8) + '$')
date = re.compile(r'^(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)?$')
isin_re = re.compile(r'^([A-Z]{2}[A-Z0-9]{9}[0-9])?$')
bad = re.compile(r'[\x00-\x08\x0b\x0c\x0e-\x1f]')
unq = lambda s: s[1:-1] if s.startswith('"') else s

rows, failed = [], []
with open(src, encoding='utf-8-sig', newline='') as fh:
    header = next(csv.reader([next(fh).rstrip('\r\n')]))
    for line in fh:
        line = line.rstrip('\r\n')
        m = pat.match(line)
        if not m:
            failed.append(line[:200]); continue
        g = list(m.groups())
        rows.append([unq(x) for x in g[:5]] + [g[5]] + [unq(x) for x in g[6:]])

ix = {h: i for i, h in enumerate(header)}
print("Header fields:", len(header))
print("Lines that did not match the pattern (should be 0):", len(failed))
for l in failed[:3]: print("  ", l)
print("Rows rebuilt:", len(rows))
print("Bad dates in lastModified/created/lastPublished (should be 0):",
      sum(1 for r in rows if not (date.match(r[ix['lastModified']]) and date.match(r[ix['created']]) and date.match(r[ix['lastPublished']]))))
print("Bad ISIN format (info):", collections.Counter(r[ix['isin']] for r in rows if not isin_re.match(r[ix['isin']])))
print("Status:", dict(collections.Counter(r[ix['status']] for r in rows)))
print("Status/lastAction:", dict(collections.Counter((r[ix['status']], r[ix['lastAction']]) for r in rows)))
blank = [r for r in rows if not r[ix['isin']]]
print("Blank ISIN rows:", len(blank), "| with linkedEntityId (should be 0):", sum(1 for r in blank if r[ix['linkedEntityId']]),
      "| ISIN without linkedEntityId (should be 0):", sum(1 for r in rows if r[ix['isin']] and not r[ix['linkedEntityId']]))
print("Distinct disclaimerIds / ISINs / types:", len({r[ix['disclaimerId']] for r in rows}),
      len({r[ix['isin']] for r in rows if r[ix['isin']]}), len({r[ix['disclaimerType']] for r in rows}))
print("Garbled characters (should be 0):", sum(1 for r in rows if any(s in r[ix['disclaimer']] for s in ('Ã', 'â€', '√'))))
print("Text starting with a quote (info):", sum(1 for r in rows if r[ix['disclaimer']].startswith('"')))
print("Text containing literal \\u001a (info):", sum(1 for r in rows if '\\u001a' in r[ix['disclaimer']]))

with open(out_csv, 'w', encoding='utf-8-sig', newline='') as fh:
    w = csv.writer(fh, quoting=csv.QUOTE_ALL)
    w.writerow(header); w.writerows(rows)
with open(out_csv, encoding='utf-8-sig', newline='') as fh:
    r2 = list(csv.reader(fh))
print("Re-read of fixed CSV: rows", len(r2) - 1, "| field counts:", dict(collections.Counter(len(x) for x in r2)),
      "| identical to rebuilt rows:", r2[1:] == rows)

wb = Workbook(write_only=True); ws = wb.create_sheet('Disclaimers'); ws.freeze_panes = 'A2'
ws.append(header)
for r in rows: ws.append([bad.sub('', c) for c in r])
wb.save(out_xlsx)
print("Saved", out_csv, "and", out_xlsx)
