library(tidyverse)
library(here)

OUT = here("data/opeds_to_label.tsv")
total <- 100

df <- read_tsv("data/oped_paragraphs_with_labels.tsv") %>% filter(
    is.na(ineq)
)
n_sources <- df$source %>% unique() %>% length()
per_source <- as.integer(total / n_sources)

df %>% group_by(source) %>% sample_n(per_source) %>% ungroup() %>% sample_frac(1) %>% write_tsv(OUT)
