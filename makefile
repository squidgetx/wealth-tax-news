default: parse_raw_xml make_paragraphs predict_relevance


# take the XML downloaded from TDM Studio and extract the metadata and text files
# Text files are placed in the 'txt-opeds' directory and metadata is written to 'opeds.tsv'
parse_raw_xml: 
	python3 parse_raw.py

# Make paragraphs for all downloaded opeds in the 'text-opeds' directory
# Then, take 'opeds.tsv' and expand it to include one row for every paragraph 
make_paragraphs:
	python3 make_paragraphs.py
	python3 prepare_paragraph_df.py

# Using a (manually labeled) set of paragraphs (run python3 lablr.py),
# calculate whether each paragraph is relevant (ie, about inequality) or not
# Outputs a tsv with classifier predictions of relevvance
predict_relevance:
	Rscript relevance.R

# Next step is to build a classifier to estimate the ideological direction of a paragraph
# We have several classifiers:
# One is based on congress speeches
# Two is based on outlet labels
# Three is based on GPT generated labels
# To do this though we need to use HPC
predict_ideo:
