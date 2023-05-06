library(tidyverse)
df <- read_tsv("oped_sample_20.tsv.labeled.tsv")
df %>%
    group_by(source) %>%
    filter(billionaire != 0) %>%
    summarize(m = mean(billionaire), n = n())

df %>%
    group_by(source) %>%
    filter(ineq != 0) %>%
    summarize(m = mean(ineq), n = n())

df %>%
    group_by(source) %>%
    filter(wealth_tax != 0) %>%
    summarize(m = mean(wealth_tax), n = n())
