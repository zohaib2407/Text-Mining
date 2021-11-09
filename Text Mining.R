# Loading the libraries

library(tidyverse)
library(lubridate)
library(pROC)
library(readxl)
library("writexl")
library(data.table)
library(tidytext)
library(SnowballC)
library(textstem)
library("textdata")

# Reading and understanding the Data

setwd("D:/Fall'21 - UIC/IDS 572 - Data Mining/Assignments/Assignment 4/yelpRestaurantReviews_sample_s21b")
data<-read.csv2("yelpRestaurantReviews_sample_s21b.csv")
glimpse(data)
length((unique(data$business_id)))
max(data$starsReview)
min(data$starsReview)
unique(data$name)
unique(data$neighborhood)
unique(data$state)
unique(data$is_open)
str(data$attributes)
str(data$categories)
head(data)
data$categories[1:2]



# Data Exploration
df<-data
df$Review<-as.factor(df$starsReview)
unique(df$Review)
qplot(df$Review, geom = "bar",xlab='Distribution of Ratings')
glimpse(df)


df_bar<-df%>%group_by(state)%>%summarise(num_ratings=n(), num_5_rat=round(sum(starsReview==5)*100/num_ratings),
                                 num_4_rat=round(sum(starsReview==4)*100/num_ratings),num_3_rat=round(sum(starsReview==3)*100/num_ratings),
                                 num_2_rat=round(sum(starsReview==2)*100/num_ratings),num_1_rat=round(sum(starsReview==1)*100/num_ratings)) %>%arrange(desc(num_ratings))
barplot(height=df_bar$num_ratings, names.arg = df_bar$state,xlab='Distribution of Ratings by state',col = 'blue')

df_bar2<-df%>%group_by(Review,state)%>%summarise(num_ratings=n())
ggplot(data = df_bar2, mapping = aes(x=Review, y=num_ratings, fill=state)) +  geom_col()


max(df$funny)
ggplot(df, aes(x= useful, y=starsReview)) +geom_point()
ggplot(df, aes(x= funny, y=starsReview)) +geom_point()
ggplot(df, aes(x= cool, y=starsReview)) +geom_point()
ggplot(df, aes(x= cool, y=funny)) +geom_point()


df%>%group_by(Review)%>%summarise(num_ratings=n(),sum_useful=sum(useful),sum_cool=sum(cool),sum_funny=sum(funny))%>%arrange(desc(sum_useful))

# Tokenize the reviews - tokenize the text of the reviews in the column named 'text'
df_Tokens <- df %>% select(review_id,starsReview, text ) %>% unnest_tokens(word, text)
dim(df_Tokens)
head(df_Tokens)

# Number of Distinct Words
df_Tokens %>% distinct(word) %>% dim()
# Removing Stop words
df_Tokens <- df_Tokens %>% anti_join(stop_words)
#count the total occurrences of different words, & sort by most frequent
df_Tokens %>% count(word, sort=TRUE) %>% top_n(10)

# Let's remove the words which are not present in at least 10 reviews
rareWords <-df_Tokens %>% count(word, sort=TRUE) %>% filter(n<10)
rareWords
df_Tokens1<-anti_join(df_Tokens, rareWords)

df_Tokens1 %>% count(word, sort=TRUE) %>% view()

#Remove the terms containing digits
df_Tokens1 <- df_Tokens1 %>% filter(str_detect(word,"[0-9]") == FALSE)
length(unique(df_Tokens1$word))
head(df_Tokens1)

# Words Associated with different STAR ratings
df_Tokens1 %>% group_by(starsReview) %>% count(word, sort=TRUE)

df_Tokens_stars <- df_Tokens1 %>% group_by(starsReview) %>% count(word, sort=TRUE)
df_Tokens_stars<- df_Tokens_stars %>% group_by(starsReview) %>% mutate(prop=n/sum(n))

df_Tokens_stars %>% group_by(starsReview) %>% arrange(desc(starsReview), desc(prop)) %>% filter(row_number()<=20)%>%ggplot(aes(word, prop))+geom_col()+coord_flip()+facet_wrap((~starsReview))

#Positive and Negative label using words associated with star ratings

pos_neg_rat_stars<- df_Tokens_stars %>% group_by(starsReview) %>% arrange(desc(starsReview), desc(prop)) %>% filter(row_number()<=20)%>% left_join( get_sentiments("bing"), by="word")%>%view()
str(pos_neg_rat_stars)
pos_neg_rat_stars <- pos_neg_rat_stars %>% na_if("NA")
unique(pos_neg_rat_stars$sentiment)
ggplot(data = pos_neg_rat_stars, mapping = aes(x=sentiment, y=n, fill=starsReview)) +  geom_col()

# Star Ratings relation with Business Star Ratings
ggplot(data=df,mapping= aes(x=starsReview,y=starsBusiness))+geom_point()
max(df$starsBusiness)
df%>%group_by(starsBusiness)%>%summarise(num_ratings=n(), num_5_rat=round(sum(starsReview==5)*100/num_ratings),
                                         num_4_rat=round(sum(starsReview==4)*100/num_ratings),num_3_rat=round(sum(starsReview==3)*100/num_ratings),
                                         num_2_rat=round(sum(starsReview==2)*100/num_ratings),num_1_rat=round(sum(starsReview==1)*100/num_ratings)) %>%arrange(desc(num_ratings))%>%arrange(desc(starsBusiness))


# Filter Tokens by Length

head(df_Tokens1)
df_Tokens1$char_len<-nchar(df_Tokens1$word)
dim(df_Tokens1)
df_Tokens2<-df_Tokens1%>%filter(char_len>=3)
dim(df_Tokens2)
length(unique(df_Tokens2$word))



# Stemming and Lemmatization
df_Tokens2_stem <- df_Tokens2 %>% mutate(word_stem = SnowballC::wordStem(word))
df_Tokens2_lemma <- df_Tokens2 %>% mutate(word_lemma = textstem::lemmatize_words(word))

head(df_Tokens2_stem)
head(df_Tokens2_lemma)

# 2. average star rating associated with each word
df_Tokens_stars$char_len<-nchar(df_Tokens_stars$word)
df_Tokens_stars<-df_Tokens_stars%>%filter(char_len>=3)
df_Tokens_stars_avg<-df_Tokens_stars %>% group_by(word) %>% summarise( avg = sum(starsReview*prop))
df_Tokens_stars_avg%>%top_n(20)
df_Tokens_stars_avg%>%top_n(-20)


head(df_Tokens_stars)
df_Tokens_bing<- df_Tokens %>% left_join( get_sentiments("bing"), by="word")
df_Tokens_bing
df_Tokens_bing <- df_Tokens_bing %>% na_if("NA")
df_Tokens_bing%>%group_by(sentiment)%>%summarise(n=n_distinct(word))%>%ggplot(aes(sentiment, n))+geom_col()+geom_text(aes(label = n), vjust = -0.2, colour = "blue")
length(unique(df_Tokens_bing$word))


df_Tokens_nrc<- df_Tokens %>% left_join( get_sentiments("nrc"), by="word")
df_Tokens_nrc <- df_Tokens_nrc %>% na_if("NA")
df_Tokens_nrc%>%group_by(sentiment)%>%summarise(n=n_distinct(word))%>%ggplot(aes(sentiment, n))+geom_col()+geom_text(aes(label = n), vjust = -0.2, colour = "blue")
+theme(plot.margin=unit(c(1,1,1.5,1.2),"cm"))


df_Tokens_afinn<- df_Tokens %>% left_join( get_sentiments("afinn"), by="word")
df_Tokens_afinn <- df_Tokens_afinn %>% na_if("NA")
df_Tokens_afinn%>%group_by(value)%>%summarise(n=n_distinct(word))%>%ggplot(aes(value, n))+geom_col()+geom_text(aes(label = n), vjust = -0.2, colour = "blue")+theme(plot.margin=unit(c(1,1,1.5,1.2),"cm"))
df_Tokens_afinn

#count the occurrences of positive/negative sentiment words in the reviews
df_Tokens_bing<- df_Tokens %>% inner_join( get_sentiments("bing"), by="word")
bing<-df_Tokens_bing %>% group_by(word,sentiment) %>% summarise(totOcc=n())%>%arrange(desc(totOcc))
bing

df_Tokens%>%filter(df_Tokens$review_id=='-K5z7DzXHJgEC1tsTLfFeA')
# Analysis based on review sentiments

df_Tokens3<-df_Tokens2%>%group_by(review_id,starsReview,word)%>%summarise(n=n())

df_Tokens3%>%filter(df_Tokens3$review_id=='-8lBjSMyKeiV1hkxBebsw')

# Lemmatize
df_Tokens3<-df_Tokens3 %>% mutate(word = textstem::lemmatize_words(word))

# Calculating TFID
df_Tokens3<-df_Tokens3 %>% bind_tf_idf(word, review_id, n)
df_Tokens3%>%view()

# Which words contribute to positive/negative sentiment ?
df_Tokens_bing<- df_Tokens3 %>% inner_join( get_sentiments("bing"), by="word")
df_Tokens_bing1<-df_Tokens_bing %>% group_by(word, sentiment) %>% summarise(totOcc=sum(n)) %>% arrange(sentiment, desc(totOcc))
df_Tokens_bing1<- df_Tokens_bing1 %>% mutate (totOcc=ifelse(sentiment=="positive", totOcc, -totOcc))
head(df_Tokens_bing1)
df_Tokens_bing1<-ungroup(df_Tokens_bing1)
df_Tokens_bing1 %>% top_n(25)
df_Tokens_bing1 %>% top_n(-25)

rbind(top_n(df_Tokens_bing1, 25), top_n(df_Tokens_bing1, -25)) %>% mutate(word=reorder(word,totOcc)) %>% ggplot(aes(word, totOcc, fill=sentiment))+geom_col()+coord_flip()

# Analysis of Review sentiments by Bing
df_Tokens_bing2 <- df_Tokens_bing %>% group_by(review_id, starsReview) %>%
  summarise(nwords=n(),posSum=sum(sentiment=='positive'),
            negSum=sum(sentiment=='negative'))
head(df_Tokens_bing2)
df_Tokens_bing2<- df_Tokens_bing2 %>% mutate(posProp=posSum/nwords, negProp=negSum/nwords)
df_Tokens_bing2<- df_Tokens_bing2%>% mutate(sentiScore=posProp-negProp)

df_Tokens_bing2 %>% group_by(starsReview) %>%summarise(avgPos=mean(posProp), avgNeg=mean(negProp), avgSentiSc=mean(sentiScore))

# Analysis of Review sentiments by NRC
df_Tokens_nrc<- df_Tokens3 %>% inner_join( get_sentiments("nrc"), by="word")
head(df_Tokens_nrc2)
df_Tokens_nrc2<-df_Tokens_nrc %>% summarise(nwords=n(),negSum=sum(sentiment %in% c('anger', 'disgust', 'fear', 'sadness', 'negative')),posSum=sum(sentiment %in% c('positive', 'joy', 'anticipation', 'trust')))                                                                                                        
df_Tokens_nrc2<- df_Tokens_nrc2 %>% mutate(posProp=posSum/nwords, negProp=negSum/nwords)
df_Tokens_nrc2<- df_Tokens_nrc2%>% mutate(sentiScore=posProp-negProp)
df_Tokens_nrc2 %>% group_by(starsReview) %>%
  summarise(avgPos=mean(posProp), avgNeg=mean(negProp), avgSentiSc=mean(sentiScore))
df_Tokens_nrc2%>%group_by(starsReview)%>%summarise(mean(sentiScore))


# Analysis of Review sentiments by Afinn
df_Tokens_afinn<- df_Tokens3 %>% inner_join(get_sentiments("afinn"), by="word")
df_Tokens_afinn2 <- df_Tokens_afinn %>% group_by(review_id, starsReview)%>% summarise(nwords=n(), sentiSum =sum(value))
df_Tokens_afinn2 %>% group_by(starsReview)%>% summarise(avgLen=mean(nwords), avgSenti=mean(sentiSum))


# Predictions based on aggregated Scores - BING

df_Tokens_bing3 <- df_Tokens_bing2 %>% mutate(hiLo = ifelse(starsReview <= 2, -1, ifelse(starsReview >=4, 1, 0 )))
df_Tokens_bing3 <- df_Tokens_bing3 %>% mutate(pred_hiLo=if_else(sentiScore > 0, 1, -1))
df_Tokens_bing4<-df_Tokens_bing3 %>% filter(hiLo!=0)
table(actual=df_Tokens_bing4$hiLo, predicted=df_Tokens_bing4$pred_hiLo )

# Predictions based on aggregated Scores - NRC

df_Tokens_nrc3 <- df_Tokens_nrc2 %>% mutate(hiLo = ifelse(starsReview <= 2, -1, ifelse(starsReview >=4, 1, 0 )))
df_Tokens_nrc3 <- df_Tokens_nrc3 %>% mutate(pred_hiLo=if_else(sentiScore > 0, 1, -1))
df_Tokens_nrc4<-df_Tokens_nrc3 %>% filter(hiLo!=0)
table(actual=df_Tokens_nrc4$hiLo, predicted=df_Tokens_nrc4$pred_hiLo )

# Predictions based on aggregated Scores - Afinn

df_Tokens_afinn3 <- df_Tokens_afinn2 %>% mutate(hiLo = ifelse(starsReview <= 2, -1, ifelse(starsReview >=4, 1, 0 )))
df_Tokens_afinn3 <- df_Tokens_afinn3 %>% mutate(pred_hiLo=if_else(sentiSum > 0, 1, -1))
df_Tokens_afinn4<-df_Tokens_afinn3 %>% filter(hiLo!=0)
table(actual=df_Tokens_afinn4$hiLo, predicted=df_Tokens_afinn4$pred_hiLo )

