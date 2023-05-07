library(tidyverse)
ALL <- "data/oped_paragraphs_with_labels.tsv"
LABELED <- "data/opeds_freshly_labeled.tsv"

# Make a df with the labels in it so that we can 
# continue labeling without overlapping later if we want
all.df <- read_tsv(ALL)
df <- read_tsv(LABELED)

merged.df <- all.df %>% left_join(
    df, 
    by=c('textfile', 'para_n', 'date', 'title', 'source'),
) %>% select(!text.y) %>% rename(text=text.x)

merged.df <- merged.df %>% mutate(
    ineq=pmin(ineq.x, ineq.y, na.rm = TRUE) ,
    billionaire=pmin(billionaire.x, billionaire.y, na.rm = TRUE) ,
    wealth_tax=pmin(wealth_tax.x, wealth_tax.y, na.rm = TRUE) 
) %>% select(!c(ineq.x, ineq.y, billionaire.x, billionaire.y, wealth_tax.x, wealth_tax.y))

merged.df %>% write_tsv('data/oped_paragraphs_with_labels.tsv')

# analysis of labels // todo move to Rmd
labeled_df <- merged.df %>% filter(!is.na(ineq))
nrow(labeled_df)
labeled_df %>%
    group_by(source) %>%
    filter(billionaire != 0) %>%
    summarize(m = mean(billionaire), n = n())

labeled_df %>%
    group_by(source) %>%
    filter(ineq != 0) %>%
    summarize(m = mean(ineq), n = n())

labeled_df %>%
    group_by(source) %>%
    filter(wealth_tax != 0) %>%
    summarize(m = mean(wealth_tax), n = n())
