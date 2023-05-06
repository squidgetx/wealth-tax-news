"""
script to take the raw xml from the proquest database and turn it into a tsv dataframe and
directory of raw text files
"""

RAW_DIR = "raw-opeds/"
TEXT_DIR = "txt-opeds/"
OUTFILE = "opeds.tsv"
import os
import csv
import bs4

records = []
for file in os.listdir(RAW_DIR):
    soup = bs4.BeautifulSoup(open(RAW_DIR + file), features="xml")
    text_raw = soup.find("Text").text
    text_soup = bs4.BeautifulSoup(text_raw, features="xml")
    paras = text_soup.findAll("p")
    source = soup.find("PubFrosting").find("Title").text
    title = soup.find("TitleAtt").find("Title").text
    date = soup.find("NumericDate").text
    textfile = TEXT_DIR + file + ".txt"
    with open(textfile, "w") as of:
        of.writelines((p.text.strip() + "\n" for p in paras))
    records.append(
        {"date": date, "source": source, "title": title, "textfile": textfile}
    )

with open(OUTFILE, "w") as of:
    writer = csv.DictWriter(
        of, fieldnames=["date", "source", "title", "textfile"], delimiter="\t"
    )
    writer.writeheader()
    writer.writerows(records)
