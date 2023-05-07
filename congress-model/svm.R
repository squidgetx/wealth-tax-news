# code to clean and preprocess congress speeches provided by gentzkow 2019

library(tidyverse)
library(here)
library(quanteda)
library(caret)
library(e1071)
library("quanteda.textstats")
# speeches_N contains a speech_id and the raw text
# descr_N contains the speech_id and the speaker name, among other variables
# N_SpeakerMap contains gives speaker specific info including party

congress_stopwords <-
    c(
        "absent", "committee", "gentlelady", "hereabout", "hereinafter", "hereto", "herewith", "nay",
        "pro", "sir", "thereabout", "therebeforn", "therein", "theretofore", "therewithal", "whereat",
        "whereinto", "whereupon", "yea", "adjourn", "con", "gentleman", "hereafter", "hereinbefore",
        "heretofore", "month", "none", "republican", "speak", "thereafter", "thereby", "thereinafter",
        "thereunder", "today", "whereby", "whereof", "wherever", "yes", "ask", "democrat", "gentlemen",
        "hereat", "hereinto", "hereunder", "mr", "now", "say", "speaker", "thereagainst", "therefor",
        "thereof", "thereunto", "whereabouts", "wherefore", "whereon", "wherewith", "yield", "can",
        "etc", "gentlewoman", "hereby", "hereof", "hereunto", "mrs", "part", "senator", "tell",
        "thereat", "therefore", "thereon", "thereupon", "whereafter", "wherefrom", "whereto", "wherewithal",
        "chairman", "gentleladies", "gentlewomen", "herein", "hereon", "hereupon", "nai", "per", "shall",
        "thank", "therebefore", "therefrom", "thereto", "therewith", "whereas", "wherein", "whereunder", "will"
    )



get_speeches <- function(N) {

    data_dir <- here("congress-model/hein-daily")

    speeches <- read_delim(paste0(data_dir, "/speeches_", N, ".txt"), delim = "|")
    speech_desc <- read_delim(paste0(data_dir, "/descr_", N, ".txt"), delim = "|")
    speakers <- read_delim(paste0(data_dir, "/", N, "_SpeakerMap.txt"), delim = "|")

    df <- speeches %>%
        merge(speech_desc %>% select(speech_id, date, word_count)) %>%
        merge(speakers %>% select(speech_id, speakerid, chamber, district, gender, party, state), by = "speech_id") %>%
        rename(text = speech) %>% 
        mutate(year = substr(date, 0, 4)) %>%
        mutate(yearmo = substr(date, 0, 6)) %>%
        filter(word_count > 200)

    df_speaker_date <- df %>%
        group_by(speakerid, date, party) %>%
        summarize(text = paste(text, collapse = " "))

    df_speaker_yearmo <- df %>% group_by(speakerid, yearmo, party) %>%
        summarize(text = paste(text, collapse = " "))

    df_speaker_year <- df %>%
        group_by(speakerid, year, party) %>%
        summarize(text = paste(text, collapse = " "))
    df_speaker_year
}

Ns <- list(113, 114)
dfs <- lapply(Ns, get_speeches)
df <- do.call("rbind", dfs)
sc <- corpus(df) %>% corpus_subset(party %in% c("D", "R"))

make_dfm <- function(corp) {
    corp %>%
        tokens(remove_punct = T, remove_numbers=T) %>%
        tokens_tolower() %>%
        tokens_remove(stopwords("en")) %>%
        tokens_remove(congress_stopwords) %>%
        tokens_wordstem() %>% 
        tokens_ngrams(n=2) %>%
        dfm()
}

make_dfm_train <- function(corp) {
    make_dfm(corp) %>% 
        dfm_trim(min_termfreq = 100) %>%
        dfm_tfidf()
}

make_dfm_test <- function(corp, train_featnames) {
    dfm <- make_dfm(corp) %>%
        dfm_match(features=train_featnames) %>% 
        dfm_tfidf()
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
    train_y <- corpus_train$party %>% as.factor()

    #model <- train(
    #    x = train_x,
    #    y = train_y,
    #    method = "svmLinear",
    #    tuneGrid = tunegrid,
    #    trControl = tc
    #)
    prob_model <- tune.svm(x = train_x, y = train_y,
                       gamma = seq(0.1, 1, 0.1), 
                       coef0 = seq(0, 1, 0.1), 
                       probability = TRUE)
    model <- svm(x = train_x, y = train_y, 
                      gamma = prob_model$best.parameters$gamma, 
                      coef0 = prob_model$best.parameters$coef0, 
                      probability = TRUE,
                      cachesize=1000
    )

    # out of sample test
    corpus_test <- corpus[-ids_train]
    test_x <- make_dfm_test(corpus_test, featnames(train_x))
    test_y <- corpus_test$party %>% as.factor()

    preds <- predict(model, newdata = test_x)
    cmat <- confusionMatrix(preds, test_y, mode='prec_recall')
    list(cmat=cmat, model=model, train_x_feat=featnames(train_x))
}

print("training...")
res <- train_svm(sc, trainProp=0.8)
save(res, file='svm_74_year_113_114.Rda')

