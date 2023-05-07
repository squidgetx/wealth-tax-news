import csv
import os

infile = "data/opeds_to_label.tsv"
outfile = "data/opeds_freshly_labeled.tsv"

class bcolors:
    HEADER = "\033[95m"
    OKBLUE = "\033[94m"
    OKCYAN = "\033[96m"
    OKGREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"


def highlight(str):
    # Surround keywords in string with highlight sequences
    keywords = [
        "wealth tax",
        "capital gains",
        "income tax",
        "estate tax",
        "inheritance tax" "1%",
        "wealthy",
        "wealthiest",
        "billionaire",
        "taxes",
    ]
    for kw in keywords:
        str = str.replace(
            kw, f"{bcolors.BOLD}{bcolors.OKGREEN}{kw}{bcolors.ENDC}{bcolors.ENDC}"
        )
    return str

records = []
reader = csv.DictReader(open(infile), delimiter="\t")
for n, row in enumerate(reader):
    wt, ineq, billionaire = '', '', ''
    while True:
        l = row['text']
        os.system("clear")
        print(f"{n}: {highlight(l)}\n")
        ineq = input(
            "General economic/inequality/taxes\n0 or empty: No mention\n1: progressive\n2: neutral\n3: conservative\n> "
        )
        billionaire = input(
            "Billionaires\n0 or empty: No mention\n1: Negative\n2: Neutral\n3: Positive\nb: restart\n>"
        )
        if billionaire == 'b':
            continue
        if (ineq == '0' or ineq == ''):
                break
        wt = input(
            "Wealth tax\n0 or empty: No mention\n1: Positive\n2: Neutral\n3: Negative\nb: restart\n> "
        )
        if wt == "b":
            continue
        break
    record = row.copy()
    record["wealth_tax"] = wt or "0"
    record["billionaire"] = billionaire or "0"
    record["ineq"] = ineq or "0"
    record["text"] = l
    records.append(record)

writer = csv.DictWriter(
open(outfile, "w"), delimiter="\t", fieldnames=records[0].keys()
)
writer.writeheader()
writer.writerows(records)
