data <- read.csv("Hotel_Reviews_Original.csv")

#************************************************************Pre-processing
Nega_count<-sapply(gregexpr("\\S+", data$Negative_Review), length)
data$Review_Total_Negative_Word_Counts<-Nega_count

#install.packages("stringr")
library(stringr)

data$Negative_Review <- str_trim(data$Negative_Review)

x1 <- str_detect(data$Negative_Review, "^Nothing$")
ind <- which(x1)
data$Review_Total_Negative_Word_Counts[x1] <- 0 

x2 <- str_detect(data$Negative_Review, "^n a$")
ind2 <- which(x2)
data$Review_Total_Negative_Word_Counts[ind2] <- 0

x3 <- str_detect(data$Negative_Review, "^No Negative$")
ind3 <- which(x3)
data$Review_Total_Negative_Word_Counts[ind3] <- 0

library(dplyr)
library(ggplot2)
library(readr)
library(stringr)
library(broom)
library(udpipe)
library(tidytext)
library(tidyr)
library(leaflet)
library(gridExtra)
library(topicmodels)
library(text2vec)
library(textmineR)


#************************** Kavya_Visualizations 1 and 2 ****************************************************
data_model=data
data_model=na.omit(data_model)
#data_model= str_trim(data_model)

data_model$country=sapply(str_split(data_model$Hotel_Address," "),function(x){x[length(x)]})
data_model$country=str_trim(data_model$country)
data_model$Reviewer_Nationality=str_trim(data_model$Reviewer_Nationality)

data_model$tourist=ifelse(data_model$Reviewer_Nationality==data_model$country,"No","Yes")
data_model$tourist=as.factor(data_model$tourist)

str(data_model)

data_model%>%group_by(country,tourist)%>%summarise(average_score=mean(Average_Score))%>%ungroup()%>%mutate(average_score=average_score**7)%>%ggplot(aes(x=country,y=average_score,color=tourist,fill=tourist))+geom_bar(stat='identity',position='dodge')+xlab("Country")+ylab("Average Score")+scale_y_continuous(breaks = NULL)

mat1<-data_model[,11]
mat2<-data_model[,13]
mat3<-data.frame(mat1,mat2)
pairs(mat3$mat1 ~ mat3$mat2)
?pairs

mat5<-data_model[,8]
mat6<-data_model[,13]
mat7<- data.frame(mat5,mat6)
pairs(mat7$mat6 ~ mat7$mat5)

x <- lm(mat7$mat5 ~ mat7$mat6)
plot(mat7$mat6 ~ mat7$mat5)
abline(x, lwd = 5, col = "red")

mat8<-data.frame(mat3,mat5)
cormat<- cor(mat8)
corrplot(cormat,method="number")

install.packages("corrplot")
library(corrplot)
?abline
var(mat7)



#************************** Kavya_Topic Modeling ****************************************************

data%>%filter(Hotel_Name=='Britannia International Hotel Canary Wharf',!is.na(Positive_Review))%>%select(Positive_Review)%>%mutate(id=1:length(Positive_Review))->pos

stop_words[length(stop_words$word)+1,]=c("hotel","Corp")
stop_words[length(stop_words$word)+1,]=c("positive","Corp")
stop_words[length(stop_words$word)+1,]=c("good","Corp")
stop_words[length(stop_words$word)+1,]=c("lovely","Corp")
stop_words[length(stop_words$word)+1,]=c("excellent","Corp")
stop_words[length(stop_words$word)+1,]=c("nice","Corp")
stop_words[length(stop_words$word)+1,]=c("canary","Corp")
stop_words[length(stop_words$word)+1,]=c("wharf","Corp")
stop_words[length(stop_words$word)+1,]=c("canary wharf","Corp")
stop_words[length(stop_words$word)+1,]=c("amazing","Corp")
stop_words[length(stop_words$word)+1,]=c("beautiful","Corp")

pos$Positive_Review <- as.character(pos$Positive_Review)

#take part of the sample
#index=sample(1:nrow(pos),0.50*nrow(pos),replace = F)
#pos=pos[index,]

#data cleaning
?sub
#pos$Positive_Review <- sub("RT.*:", "", pos$Positive_Review)
#pos$Positive_Review <- sub("@.* ", "", pos$Positive_Review)

#data cleaning
pos$Positive_Review <- as.character(pos$Positive_Review)

text_cleaning_tokens <- pos %>% 
  tidytext::unnest_tokens(word, Positive_Review)
text_cleaning_tokens$word <- gsub('[[:digit:]]+', '', text_cleaning_tokens$word)
text_cleaning_tokens$word <- gsub('[[:punct:]]+', '', text_cleaning_tokens$word)
text_cleaning_tokens <- text_cleaning_tokens %>% filter(!(nchar(word) == 1))%>% 
  anti_join(stop_words)
tokens <- text_cleaning_tokens %>% filter(!(word==""))
tokens <- tokens %>% mutate(ind = row_number())
tokens <- tokens %>% group_by(id) %>% mutate(ind = row_number()) %>%
  tidyr::spread(key = ind, value = word)
tokens [is.na(tokens)] <- ""
tokens <- tidyr::unite(tokens, text,-id,sep =" " )
tokens$text <- trimws(tokens$text)



#Create dtm
dtm<- CreateDtm(tokens$text,doc_names = tokens$id, ngram_window = c(1, 2))

tf <- TermDocFreq(dtm = dtm)
original_tf <- tf %>% select(term, term_freq,doc_freq)
rownames(original_tf) <- 1:nrow(original_tf)


# Eliminate words appearing less than 2 times or in more than half of the
# documents
vocabulary <- tf$term[ tf$term_freq > 1 & tf$doc_freq < nrow(dtm) / 2 ]
index1=sample(1:nrow(dtm),0.5*nrow(dtm),replace = F)
dtm=dtm[index1,]

#coherence score
k_list <- seq(1, 10, by = 1)
model_dir <- paste0("models_", digest::digest(vocabulary, algo = "sha1"))
if (!dir.exists(model_dir)) dir.create(model_dir)
model_list <- TmParallelApply(X = k_list, FUN = function(k){
  filename = file.path(model_dir, paste0(k, "_topics.rda"))
  
  if (!file.exists(filename)) {
    m <- FitLdaModel(dtm = dtm, k = k, iterations = 1000)
    m$k <- k
    m$coherence <- CalcProbCoherence(phi = m$phi, dtm = dtm, M = 5)
    save(m, file = filename)
  } else {
    load(filename)
  }
  m
}, export=c("dtm", "model_dir")) 

#model_list<-data.frame(words = unlist(words))
#model tuning
#choosing the best model
coherence_mat <- data.frame(k = sapply(model_list, function(x) nrow(x$phi)), 
                            coherence = sapply(model_list, function(x) mean(x$coherence)), 
                            stringsAsFactors = FALSE)
ggplot(coherence_mat, aes(x = k, y = coherence)) +
  geom_point() +
  geom_line(group = 1)+
  ggtitle("Best Topic by Coherence Score") + theme_minimal() +
  scale_x_continuous(breaks = seq(1,10,1)) + ylab("Coherence")

#See top words
model <- model_list[which.max(coherence_mat$coherence)][[ 1 ]]
model$top_terms <- GetTopTerms(phi = model$phi, M = 5)
top10_wide <- as.data.frame(model$top_terms)
View(top10_wide)

#Plot dendogram
model$topic_linguistic_dist <- CalcHellingerDist(model$phi)
model$hclust <- hclust(as.dist(model$topic_linguistic_dist), "ward.D")
model$hclust$labels <- paste(model$hclust$labels, model$labels[ , 1])
plot(model$hclust)

#Visualize
final_summary_words <- data.frame(top_terms = t(model$top_terms))
final_summary_words$topic <- rownames(final_summary_words)
rownames(final_summary_words) <- 1:nrow(final_summary_words)

#install to use the function melt
#install.packages("reshape2")
library(reshape2)

final_summary_words <- final_summary_words %>% melt(id.vars = c("topic"))
final_summary_words <- final_summary_words %>% rename(word = value) %>% select(-variable)

#install.packages("shiny")
library(shiny)
#install.packages("ggvis")
library(ggvis)
#install.packages("datasets")
library(datasets)


#final_summary_words <- final_summary_words %>% group_by(topic,word) %>%
#arrange(desc(value))
final_summary_words <- final_summary_words %>% group_by(topic, word) %>% filter(row_number() == 1) %>% 
  ungroup() %>% tidyr::separate(topic, into =c("t","topic")) %>% select(-t)

word_topic_freq <- left_join(final_summary_words, original_tf, by = c("word" = "term"))
pdf("cluster.pdf")

#install.packages("wordcloud")
#install.packages("wordcloud2")
library(wordcloud)
for(i in 1:length(unique(final_summary_words$topic)))
{  wordcloud(words = subset(final_summary_words ,topic == i)$word, freq = subset(word_topic_freq ,topic == i)$term_freq, min.freq = 2,
             max.words=200, random.order=FALSE, rot.per=0.35, 
             colors=brewer.pal(8, "Dark2"))}
dev.off()



?wordcloud

summary(data$Hotel_Name)
?mutate

