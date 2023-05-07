# train the svm

library(tidyverse)
library(here)
library(quanteda)
library(caret)
library(e1071)
library("quanteda.textstats")

outlet_stopwords <-
    c(
        "new_york_times", "wall_street_journal", "ny_times", "nyt", "wall_st_journal", "journal", "times", "wsj", "wsj+"
    )

preprocess <- function(corp) {
    tokens <- corpus(corp) %>%
        tokens(remove_punct = T, remove_symbols = T, remove_numbers = T) %>%
        tokens_tolower() %>%
        tokens_remove(stopwords("en"))
    colocs <- textstat_collocations(tokens, min_count = 5)
    tokens %>% tokens_compound(colocs) %>%
    tokens_remove(outlet_stopwords) 
}

make_dfm <- function(tokens) {
    tokens %>% dfm()
}

make_dfm_train <- function(corp) {
    make_dfm(corp) %>%
        dfm_trim(min_termfreq = 2)
}

make_dfm_test <- function(corp, train_featnames) {
    dfm <- make_dfm(corp) %>%
        dfm_match(features = train_featnames)
}

train_svm <- function(corpus, trainProp) {
    tc <- trainControl(method = "cv", number = 5)
    tunegrid <- expand.grid(C = seq(from = 0.1, to = 5.1, by = 0.75))

    ids_train <- createDataPartition(
        1:length(corpus),
        p = trainProp, list = FALSE, times = 1
    )
    corpus_train <- corpus[ids_train]
    train_x <- make_dfm_train(corpus_train)
    train_y <- corpus_train$source %>% as.factor()

    prob_model <- tune.svm(
        x = train_x, y = train_y,
        gamma = seq(0.1, 1, 0.1),
        coef0 = seq(0, 1, 0.1),
        probability = TRUE
    )
    model <- svm(
        x = train_x, y = train_y,
        gamma = prob_model$best.parameters$gamma,
        coef0 = prob_model$best.parameters$coef0,
        probability = TRUE
    )

    # out of sample test
    corpus_test <- corpus[-ids_train]
    test_x <- make_dfm_test(corpus_test, featnames(train_x))
    test_y <- corpus_test$source %>% as.factor()

    preds <- predict(model, newdata = test_x)
    cmat <- confusionMatrix(preds, test_y, mode = "prec_recall")
    list(
        cmat = cmat, 
        model = model, 
        ids_train = ids_train, 
        train_x_feat = featnames(train_x), 
        prob_model=prob_model
    )
}
