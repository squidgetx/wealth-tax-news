library(quanteda.textmodels)
library(quanteda.textstats)
library(quanteda)
library(tidyverse)
library(readtext)
library(here)

# todo move this somewhere
preprocess <- function(corp) {
    tokens <- corpus(corp) %>%
        tokens(remove_punct = T, remove_symbols = T, remove_numbers = T) %>%
        tokens_tolower() %>%
        tokens_remove(stopwords("en"))
    colocs <- textstat_collocations(tokens, min_count = 5)
    tokens %>% tokens_compound(colocs)
}
opeds <- read_tsv("oped.paragraphs.relevance.tsv")
labeled <- read_tsv(here("oped_sample_20.tsv.labeled.tsv")) %>% mutate(rn = row_number())

train_wf_manual <- function(opeds, labeled, subset_var, pos_i, neg_i) {
    # pos_i is the row number in the labeled dataset
    positive_wt_candidate <- labeled %>% filter(rn == pos_i)
    negative_wt_candidate <- labeled %>% filter(rn == neg_i)

    dir <- c(which(
        opeds$textfile == positive_wt_candidate$textfile & opeds$para_n == positive_wt_candidate$para_n,
    ), which(
        opeds$textfile == negative_wt_candidate$textfile & opeds$para_n == negative_wt_candidate$para_n,
    ))
    dfm <- opeds %>%
        preprocess() %>%
        dfm()
    dfm.sub <- dfm %>%
        dfm_subset(opeds[, subset_var][[1]]) %>%
        dfm_trim(min_termfreq = 2)
    textmodel_wordfish(dfm.sub, dir = dir)
}

train_wf_gpt <- function(opeds, suffix, subset_var) {
    gpt_corp <- readtext(c(
        here(paste0(
            "gpt-opeds/gpt-against-", suffix, ".txt"
        )),
        here(paste0(
            "gpt-opeds/gpt-for-", suffix, ".txt"
        ))
    ))

    gpt_corp$date <- NA
    gpt_corp$title <- NA
    gpt_corp$para_n <- NA
    gpt_corp$about_ineq_pred <- NA
    gpt_corp$about_billion_pred <- NA
    gpt_corp$about_wt_pred <- NA
    gpt_corp$about_wt_manual <- NA
    gpt_corp$source <- "gpt"
    gpt_corp <- gpt_corp %>% rename(textfile = doc_id)
    # Set the subset var of the gpt text to 1
    gpt_corp[, subset_var] <- 1

    gpt.corp <- rbind(gpt_corp, opeds)
    gpt.dfm <- preprocess(gpt.corp) %>%
        dfm() %>%
        dfm_subset(about_wt_manual == 1) %>%
        dfm_trim(min_termfreq = 2)

    textmodel_wordfish(dfm, dir = c(0, 1))
}

wf.vanilla <- train_wf_manual(opeds, labeled, "about_wt_manual", 15, 99)
wf.gpt <- train_wf_gpt(opeds, "ineq", "about_wt_manual")
wf.wealth_tax <- list(vanilla = wf.vanilla, gpt = wf.gpt)
save(wf.wealth_tax, file=here("wordfish/wf.wealth_tax.Rda"))
