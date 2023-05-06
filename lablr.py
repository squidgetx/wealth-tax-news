import csv
import os


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


infile = "oped_sample_20.tsv"
outfile = infile + ".labeled.tsv"


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


reader = csv.DictReader(open(infile), delimiter="\t")
total = 0
for i, row in enumerate(reader):
    with open(row["textfile"].replace("txt-", "para-")) as txt:
        lines = txt.readlines()
        total += len(lines)
        continue

records = []
reader = csv.DictReader(open(infile), delimiter="\t")
n = 0
for row in reader:
    with open(row["textfile"].replace("txt-", "para-")) as txt:
        lines = txt.readlines()
 
        for i, l in enumerate(lines):
            wt, ineq, billionaire = '', '', ''
            while True:
                os.system("clear")
                print(f"{n}/{total}: {highlight(l)}\n")
                n+= 1
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
            record["para_n"] = i
            record["text"] = l
            records.append(record)

writer = csv.DictWriter(
    open(outfile, "w"), delimiter="\t", fieldnames=records[0].keys()
)
writer.writeheader()
writer.writerows(records)

# Notes - some articles show up because there is like a link to another article (about wealth tax) in there - can we get rid of these somehow?
# Most of the off topic stuff is because there are articles about the democratic race in general
# There is a dimension of "wealth tax terrible idea" vs. "wealth tax bad idea but we should raise capital gains taxes, etc." which we may want to disambiguate more?
