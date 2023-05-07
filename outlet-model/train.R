library(here)
source(here('outlet-model/svm.R'))

outlet.corpus <- read_tsv(here("oped.paragraphs.relevance.tsv")) %>%
    preprocess()  %>%
    tokens_subset(source %in% c("Wall Street Journal (Online)", "New York Times (Online)"))

print("training...")
res <- train_svm(outlet.corpus, trainProp = 0.8)
save(res, file = here("outlet-model/svm.Rda"))
