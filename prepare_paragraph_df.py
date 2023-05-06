INFILE = 'opeds.tsv'
OUTFILE = 'oped_paragraphs.tsv'

# Input is list of articles
# Output is list of article-paragraphs
import csv

reader = csv.DictReader(open(INFILE), delimiter="\t")
records = []
for i, row in enumerate(reader):
    with open(row["textfile"].replace("txt-", "para-")) as txt:
        lines = txt.readlines()
        for j, line in enumerate(lines):
            record = row.copy()
            record['text'] = line.strip()
            record['para_n'] = j
            records.append(record)

with open(OUTFILE, 'w') as of:
    writer = csv.DictWriter(of, delimiter='\t', fieldnames=records[0].keys())
    writer.writeheader()
    writer.writerows(records)