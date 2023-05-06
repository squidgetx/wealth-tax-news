"""
Script to turn raw op ed texts into paragraphs
Also cleans out lines that are not related
"""
import os
import re

PARA_MIN = 75
INFILE = "opeds.tsv"
TEXT_DIR = "txt-opeds"
PARAS_DIR = "para-opeds"


def is_bad_para(para):
    prefixes = [
        "credit: ",
        "crédito:",
        "you're reading",
        "click here",
        "send us",
        "coverage from ",
        "enter email",
        "get the latest",
        "sign me up",
        "sign up",
        "you may occasionally receive promotional",
        "latest from",
        "the times is committed",
        "follow the",
        "opinion columnist",
        "to the editor",
        "@",
        "more back in business",
        "published",
        "receive the next",
        "more opinions essays",
        "read more",
        "share your thoughts",
        "write to",
        "register with",
        "to suggest",
    ]
    for prefix in prefixes:
        if para.lower().startswith(prefix):
            return True

    # kill paragraphs that are 2 words long or fewer
    if len(para.split(" ")) <= 2:
        return True

    # kill paragraphs that look like article recommendations
    if re.search("by ([A-Z][a-zA-Z'-]+) ([A-Z][a-zA-Z'-]+)$", para.strip()):
        return True

    # kill paragraphs that look like bylines
    if re.match("([A-Z][a-zA-Z'.-]+[ ]?){2,3}, ([A-Z][a-zA-Z'-]+[ ]?){1,2}$", para):
        return True
    return False


def merge_lines_suffixes(lines):
    # If a paragraph ends with a colon, concatenate it with the next one
    new_lines = []
    i = 0
    while i < len(lines):
        cur = lines[i]
        if (cur.endswith(":") or cur.endswith(",")) and i < len(lines) - 1:
            nxt = lines[i + 1]
            new_lines.append(cur + " " + nxt)
            i += 2
        else:
            new_lines.append(cur)
            i += 1
    return new_lines


def merge_lines_prefixes(lines):
    # If a paragraph starts with a lowercase letter or comma,
    # concatenate it with the previous one
    new_lines = []
    i = 0
    while i < len(lines):
        cur = lines[i]
        if i < len(lines) - 1 and (re.match("^[a-z,]", lines[i + 1])):
            new_lines.append(cur + " " + lines[i + 1])
            i += 2
        else:
            new_lines.append(cur)
            i += 1
    return new_lines


def make_greedy_paras(lines):
    # Simple algorithm - merge lines starting at the beginning of the article
    # until the paragraph reaches a minimum of 25 words
    new_lines = []
    i = 0
    while i < len(lines):
        current_line = ""
        while len(current_line.split(" ")) < PARA_MIN and i < len(lines):
            current_line += lines[i].strip() + " "
            i += 1
        new_lines.append(current_line)
    return new_lines


for file in os.listdir(TEXT_DIR):
    with open(f"{TEXT_DIR}/{file}") as f:
        lines = f.readlines()
        good_lines = [l.strip() for l in lines if not is_bad_para(l)]
        merged_lines = merge_lines_suffixes(good_lines)
        merged_lines = merge_lines_prefixes(merged_lines)
        greedy = make_greedy_paras(merged_lines)

        outfile = f"{PARAS_DIR}/{file}"
        with open(outfile, "w") as of:
            of.writelines((m + "\n" for m in greedy))
