# Hotel-Reviews-Analysis
This project is based on the 515K Hotel Reviews dataset from kaggle. This can be found here: https://www.kaggle.com/jiashenliu/515k-hotel-reviews-data-in-europe. The code is written in R, and focuses on two main components: 

1) Data Visualization:
  a) Tourist vs Average score: I want to see if there is any bias from the local customers in giving the reviewer score for the hotels. If the customer belongs to the same country as the hotel location, he/she is local. Otherwise, tourist. 
  
  b) Count of review words vs customer rating: I wanted to see if there is a correlation between the positive word count and reviewer score, and negative word count and reviewer score. Intuitively, we assume that if the positive word count is more, there might be a higher score given by the customer, and the opposite for negative. So, I wanted to plot scatter diagrams and check if there is any correlation.
  
2) Topic Modeling on user given reviews using Latent Dirichlet Allocation:
Clustering is the process of grouping class objects into clusters which have most similar objects within the cluster as compared with the other clusters. As text is in unstructured format, we use unsupervised algorithms to separate the text into clusters.  In this project, we are dealing with lots of positive and negative reviews to understand the pros and cons given by the guests staying in hotels.

