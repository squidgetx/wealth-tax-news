library(here)
library(quanteda)
library(parallel)
source(here('label-model/svm.R'))

label.corpus <- read_tsv(here("data/oped_paragraphs_with_labels.tsv")) %>%
    filter(!is.na(ineq)) %>%
    preprocess()

print("training...")
Nsims <- 100
ineq.labels <- label.corpus %>% tokens_subset(ineq %in% c(1,3))
allresults <- mclapply(
    1:Nsims, 
    function(i) { train_svm(ineq.labels, 'ineq', trainProp = 0.8) }
)
save(allresults, file = here("label-model/svm-ineq-repeated.Rda"))
