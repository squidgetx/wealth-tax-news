# code to evaluate the model

library(tidyverse)
library(here)
source(here("outlet-model/svm.R"))

load(file=here("outlet-model/svm.Rda"))
res$cmat

# the classifier is pretty good at distinguishing NYT/WSJ articles

df <- read_tsv(here('oped_sample_20.tsv.labeled.tsv')) %>% mutate(
    ineq_ideo = ifelse(ineq == 0 | ineq == '', NA, ineq),
    billion_ideo = ifelse(billionaire == 0 | billionaire == '', NA, billionaire),
    wealth_ideo = ifelse(wealth_tax == 0 | wealth_tax == '', NA, wealth_tax)
)

test_x <- df %>% preprocess() %>% make_dfm_test(res$train_x_feat)
df$pred <- predict(res$model, newdata=test_x, prob=TRUE)
df$pred_nyt_prob <- attr(df$pred, 'probabilities')[,1]
df$pred_wsj_prob <- attr(df$pred, 'probabilities')[,2]


# but it's actually ass at distinguishing ineq ideo within the labeled dataset
df %>% ggplot(aes(x=ineq_ideo, y=pred_nyt_prob)) + geom_point()
cor(df$ineq_ideo, -df$pred_nyt_prob, use='complete.obs')
cor(df$ineq_ideo, df$pred_wsj_prob, use='complete.obs')

cor(df$billion_ideo, -df$pred_nyt_prob, use='complete.obs')

cor(df$wealth_ideo, -df$pred_nyt_prob, use='complete.obs')
