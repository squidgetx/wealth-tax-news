library(tidyverse)
library(readtext)
df <- read_tsv("opeds.tsv")
# writing sample validation set for labelling
df %>%
    group_by(source) %>%
    sample_n(5) %>%
    write_tsv("oped_sample_20.tsv")

hist(df$date, breaks = 100)
table(df$source)

corp <- readtext(df$textfile, docvarsfrom = "filepaths") %>%
    merge(df, by.x = "docvar1", by.y = "textfile")

corp %>%
    sample_n(100) %>%
    write_tsv("oped_sample_100.tsv")


# use LDA to throw out any articles that are not obviously related
library(quanteda)
library(topicmodels)
dfm <- corpus(corp) %>%
    tokens(remove_punct = T, remove_numbers = T, remove_url = T) %>%
    tokens_tolower() %>%
    tokens_remove(stopwords("en")) %>%
    tokens_select(min_nchar = 2) %>%
    dfm() %>%
    dfm_remove(
        as.logical(dfm[, c("wealth_tax")] == 0)
    ) %>%
    dfm_trim(min_termfreq = 2) %>%
    dfm_subset(ntoken(.) > 0)

lda() <- LDA(dfm, k = 8, method = "Gibbs", control = list(seed = 1234, iter = 3000))
get_terms(lda, 10)
table(topics(lda))

# okay, no obvious way for LDA to be useful here...
# so, maybe we need to manually label ?

# prompt for gpt-against.txt
# Write a short essay arguing for a wealth tax on high earners in the United States in the style of a newspaper editorial

# prompt for gpt-for.txt
# Write a short essay arguing for a wealth tax on high earners in the United States in the style of a newspaper editorial

gpt_corp <- readtext(c("gpt-opeds/gpt-against.txt", "gpt-opeds/gpt-for.txt"), docvarsfrom = "filepaths")

gpt_corp$date <- NA
gpt_corp$title <- NA
gpt_corp$source <- "gpt"

all_corp <- rbind(gpt_corp, corp)

library(quanteda.textmodels)
wf <- textmodel_wordfish(dfm, dir = c(0, 1))
list(theta = wf$theta) %>%
    cbind(dfm %>% docvars()) %>%
    arrange(theta)
weights <- wf$beta
words <- wf$psi # values
names(words) <- wf$features # the words

temp <- data.frame(words = names(words), fixedeffect = words, marginaleffect = weights)
library(ggrepel)
ggplot(temp, aes(marginaleffect, fixedeffect)) +
    geom_text_repel(
        data = temp %>% filter(abs(marginaleffect) > 3 | fixedeffect > 3),
        aes(marginaleffect, fixedeffect, label = words),
        size = 4,
        max.overlaps = 20
    ) +
    geom_point(alpha = 0.2) +
    theme_bw() +
    scale_x_continuous(limits = c(-6, 8)) +
    scale_y_continuous(limits = c(-8, 5))
