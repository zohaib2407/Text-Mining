# Text-Mining
Text Mining using Yelp reviews data 

This analysis involves the analyses of text data on users’ review of restaurants and sentiment
analysis. It is based on a collection of reviews and accompanying star ratings from Yelp. To keep the
analysis manageable, a sample of the original dataset (over 8 million reviews by over a million
users for 160K+ businesses) will be used here. We will examine the effectiveness of different sentiment
‘dictionaries’, and develop and evaluate classification models to help predict sentiment polarity
(negative, positive). 
The star ratings will be used here to indicate the sentiment label. For binary classification, we will need
to convert the 1-5 scale rating values to {positive(1), negative(0)} values.
(More details on the data are available from https://www.yelp.com/dataset) 
We will consider reviews for restaurants. The data has been pre-processed to get the business type,
review text, star rating, and how many users found this review to be cool, funny, useful, into a single file
which you will use for the analyses.
