## R sample code for the Linux data science VM (https://azure.microsoft.com/en-us/marketplace/partners/microsoft-ads/linux-data-science-vm/)

# before running the code, download the spambase data file and add a header. At a command line:
# wget http://archive.ics.uci.edu/ml/machine-learning-databases/spambase/spambase.data
# echo 'word_freq_make, word_freq_address, word_freq_all, word_freq_3d,word_freq_our, word_freq_over, word_freq_remove, word_freq_internet,word_freq_order, word_freq_mail, word_freq_receive, word_freq_will,word_freq_people, word_freq_report, word_freq_addresses, word_freq_free,word_freq_business, word_freq_email, word_freq_you, word_freq_credit,word_freq_your, word_freq_font, word_freq_000, word_freq_money,word_freq_hp, word_freq_hpl, word_freq_george, word_freq_650, word_freq_lab,word_freq_labs, word_freq_telnet, word_freq_857, word_freq_data,word_freq_415, word_freq_85, word_freq_technology, word_freq_1999,word_freq_parts, word_freq_pm, word_freq_direct, word_freq_cs, word_freq_meeting,word_freq_original, word_freq_project, word_freq_re, word_freq_edu,word_freq_table, word_freq_conference, char_freq_semicolon, char_freq_leftParen,char_freq_leftBracket, char_freq_exclamation, char_freq_dollar, char_freq_pound, capital_run_length_average,capital_run_length_longest, capital_run_length_total, spam' > headers
# cat spambase.data >> headers
# mv headers spambaseHeaders.data

data <- read.csv("spambaseHeaders.data")
set.seed(123)

# examine the data
summary(data)
str(data)

# spam was read as an integer, but it's a factor
data$spam <- as.factor(data$spam)

## make a few plots

library(ggplot2)

# plot the frequency of the exclamation mark character
ggplot(data) + geom_histogram(aes(x=char_freq_exclamation), binwidth=0.25)

# the zero bar is skewing the plot, so remove it
email_with_exclamation = data[data$char_freq_exclamation > 0, ]
ggplot(email_with_exclamation) + geom_histogram(aes(x=char_freq_exclamation), binwidth=0.25)

# look at the density above 1%
ggplot(data[data$char_freq_exclamation > 1, ]) + geom_histogram(aes(x=char_freq_exclamation), binwidth=0.25)

# and split it by spam vs ham
ggplot(data[data$char_freq_exclamation > 1, ], aes(x=char_freq_exclamation)) +
geom_density(lty=3) +
	geom_density(aes(fill=spam, colour=spam), alpha=0.55) +
	xlab("spam") +
	ggtitle("Distribution of spam \nby frequency of !") +
	labs(fill="spam", y="Density")

## create train and test sets
rnd <- runif(dim(data)[1])
trainSet = subset(data, rnd <= 0.7)
testSet = subset(data, rnd > 0.7)

## make a decision tree
require(rpart)
model.rpart <- rpart(spam ~ ., method = "class", data = trainSet)
plot(model.rpart)
text(model.rpart)

# and see how well it performs
testSetPred <- predict(model.rpart, newdata = testSet, type = "class")
t <- table(`Actual Class` = testSet$spam, `Predicted Class` = testSetPred)
accuracy <- sum(diag(t))/sum(t)
print(paste0("Decision tree test set accuracy is ", accuracy))

## try a random forest
require(randomForest)
trainVars <- setdiff(colnames(data), 'spam')
model.rf <- randomForest(x=trainSet[, trainVars], y=trainSet$spam)

# and see how well it does
trainSetPred <- predict(model.rf, newdata = trainSet[, trainVars], type = "class")
table(`Actual Class` = trainSet$spam, `Predicted Class` = trainSetPred)
testSetPred <- predict(model.rf, newdata = testSet[, trainVars], type = "class")
t <- table(`Actual Class` = testSet$spam, `Predicted Class` = testSetPred)
accuracy <- sum(diag(t))/sum(t)
print(paste0("Random forest test set accuracy is ", accuracy))

## xgboost

require(xgboost)

trainSet$spam <- as.numeric(levels(trainSet$spam))[trainSet$spam]
testSet$spam <- as.numeric(levels(testSet$spam))[testSet$spam]
bst <- xgboost(data = data.matrix(trainSet[,0:57]), label = trainSet$spam, nthread = 2, nrounds = 2, objective = "binary:logistic")

pred <- predict(bst, data.matrix(testSet[, 0:57]))
accuracy <- 1.0 - mean(as.numeric(pred > 0.5) != testSet$spam)
print(paste("xgboost test accuracy = ", accuracy))

## finally, publish a simplified decision tree to AzureML. If you don't have an account, sign up for one at https://studio.azureml.net/.
require(AzureML)

# Enter your workspace ID and authorization token here. To find them, sign in to the 
# Azure Machine Learning Studio. You'll need your workspace ID and an authorization token. 
# To find these, click Settings on the left-hand menu. Note your workspace ID. 
# Next click Authorization Tokens from the overhead menu and note your Primary Authorization Token.
wsAuth = "<authorization-token>"
wsID = "<workspace-id>"

# make a simplified decision tree
colNames <- c("char_freq_dollar", "word_freq_remove", "word_freq_hp", "spam")
smallTrainSet <- trainSet[, colNames]
smallTestSet <- testSet[, colNames]
model.rpart <- rpart(spam ~ ., method = "class", data = smallTrainSet)

predictSpam <- function(char_freq_dollar, word_freq_remove, word_freq_hp) {
    predictDF <- predict(model.rpart, data.frame("char_freq_dollar" = char_freq_dollar,
    "word_freq_remove" = word_freq_remove, "word_freq_hp" = word_freq_hp))
    return(colnames(predictDF)[apply(predictDF, 1, which.max)])
}

# publish it to AzureML
spamWebService <- publishWebService("predictSpam",
    "spamWebService",
    list("char_freq_dollar"="float", "word_freq_remove"="float","word_freq_hp"="float"),
    list("spam"="int"),
    wsID, wsAuth)

# view some information about the published endpoint
spamWebService[[2]]

# and call it
consumeDataframe(spamWebService$endpoints[[1]]$PrimaryKey, spamWebService$endpoints[[1]]$ApiLocation, smallTestSet[1:10, 1:3])