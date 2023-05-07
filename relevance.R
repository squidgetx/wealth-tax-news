# train a simple classifier to determine whether a paragraph is "relevant" or not
# we actually train 3 different classifiers - wealth tax, billionaire, and inequality
library(tidyverse)
library(quanteda)
library(quanteda.textstats)
library(quanteda.textmodels)
library(caret)

LABELED <- here("data/oped_paragraphs_with_labels.tsv")
OUTFILE <- here("data/oped.paragraphs.relevance.tsv")



preprocess <- function(corp) {
    tokens <- corpus(corp) %>%
        tokens(remove_punct = T, remove_symbols = T, remove_numbers = T) %>%
        tokens_tolower() %>%
        tokens_remove(stopwords("en"))
    colocs <- textstat_collocations(tokens, min_count = 5)
    tokens %>% tokens_compound(colocs)
}



assign_tt_split <- function(dfm, trainProp) {
    train <- sample(c(0, 1), nrow(labeled), prob = c(1 - trainProp, trainProp), replace = TRUE)
    docvars(dfm)$train <- train
    dfm
}

train_model <- function(dfm, yvar) {
    # Requires indicator 'train' variable in dfm
    train.x <- dfm_subset(dfm, train == 1)
    train.y <- docvars(train.x)[[yvar]]
    model <- textmodel_nb(train.x, train.y, prior = "docfreq")
    model
}

evaluate_model <- function(dfm, model, yvar) {
    test.x <- dfm_subset(dfm, train == 0)
    test.y <- docvars(test.x)[[yvar]] %>% as.factor()
    preds <- predict(model, test.x)
    confusionMatrix(preds, test.y, mode = "prec_recall", positive = "TRUE")
}

labeled <- read_tsv(LABELED) %>% filter(!is.na(ineq)) %>% mutate(
    about_ineq = !(ineq == 0 | ineq == ""),
    about_billion = !(billionaire == 0 | billionaire == ""),
    about_wt = !(wealth_tax == 0 | wealth_tax == ""),
)
tokens <- preprocess(labeled)
dfm <- tokens %>%
    dfm() %>%
    dfm_trim(min_termfreq = 2)

model_featnames <- featnames(dfm)
dfm.tt <- assign_tt_split(dfm, 0.7)

ineq.model <- train_model(dfm.tt, "about_ineq")
evaluate_model(dfm.tt, ineq.model, "about_ineq")

billion.model <- train_model(dfm.tt, "about_billion")
evaluate_model(dfm.tt, billion.model, "about_billion")

wt.model <- train_model(dfm.tt, "about_wt")
evaluate_model(dfm.tt, wt.model, "about_wt")


# terrible performance for the wt model
# can we investigate the distinguishing words?
# fuck it we'll just use a basic keyword model for this one: "wealth_tax" or "wealth_taxation"

all.df <- read_tsv(LABELED)

all.tokens <- preprocess(all.df)
all.dfm <- all.tokens %>%
    dfm() %>%
    dfm_trim(min_termfreq = 2)
all.dfm.matched <- dfm_match(all.dfm, model_featnames)

all.df$about_ineq_pred <- predict(ineq.model, all.dfm.matched)
all.df$about_billion_pred <- predict(billion.model, all.dfm.matched)
all.df$about_wt_pred <- predict(wt.model, all.dfm.matched)
all.df$about_wt_manual <- str_detect(tolower(all.df$text), "wealth tax")
all.df %>% write_tsv(OUTFILE)
save(all.df, file = "opeds.Rda")
save(all.dfm, file = "opeds.dfm.Rda")
