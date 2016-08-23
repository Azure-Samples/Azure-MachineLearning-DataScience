## Python sample code for the Linux data science VM (https://azure.microsoft.com/en-us/marketplace/partners/microsoft-ads/linux-data-science-vm/)

# before running the code, download the spambase data file and add a header. At a command line:
# wget http://archive.ics.uci.edu/ml/machine-learning-databases/spambase/spambase.data
# echo 'word_freq_make, word_freq_address, word_freq_all, word_freq_3d,word_freq_our, word_freq_over, word_freq_remove, word_freq_internet,word_freq_order, word_freq_mail, word_freq_receive, word_freq_will,word_freq_people, word_freq_report, word_freq_addresses, word_freq_free,word_freq_business, word_freq_email, word_freq_you, word_freq_credit,word_freq_your, word_freq_font, word_freq_000, word_freq_money,word_freq_hp, word_freq_hpl, word_freq_george, word_freq_650, word_freq_lab,word_freq_labs, word_freq_telnet, word_freq_857, word_freq_data,word_freq_415, word_freq_85, word_freq_technology, word_freq_1999,word_freq_parts, word_freq_pm, word_freq_direct, word_freq_cs, word_freq_meeting,word_freq_original, word_freq_project, word_freq_re, word_freq_edu,word_freq_table, word_freq_conference, char_freq_semicolon, char_freq_leftParen,char_freq_leftBracket, char_freq_exclamation, char_freq_dollar, char_freq_pound, capital_run_length_average,capital_run_length_longest, capital_run_length_total, spam' > headers
# cat spambase.data >> headers
# mv headers spambaseHeaders.data

import pandas
data = pandas.read_csv("spambaseHeaders.data", sep = ',\s*')
X = data.ix[:, 0:57]
y = data.ix[:, 57]

# make a support vector classifier
from sklearn import svm    
clf = svm.SVC()
clf.fit(X, y)

# and do some predictions
clf.predict(X.ix[0:20, :])

## finally publish a simplified model to AzureML

# If you don't have an account, sign up for one at 
# https://studio.azureml.net/. This is supported for 
# python 2.7 but not python 3.5, so you should 
# run it with /anaconda/bin/python2.7.

# Make a simpler model
X = data.ix[["char_freq_dollar", "word_freq_remove", "word_freq_hp"]]
y = data.ix[:, 57]
clf = svm.SVC()
clf.fit(X, y)

# Enter your workspace ID and authorization token here. To find them, sign in to the 
# Azure Machine Learning Studio. You'll need your workspace ID and an authorization token. 
# To find these, click Settings on the left-hand menu. Note your workspace ID. 
# Next click Authorization Tokens from the overhead menu and note your Primary Authorization Token.
workspace_id = "<workspace-id>"
workspace_token = "<workspace-token>"

# and publish the model to AzureML
from azureml import services
@services.publish(workspace_id, workspace_token)
@services.types(char_freq_dollar = float, word_freq_remove = float, word_freq_hp = float)
@services.returns(int) # 0 or 1
def predictSpam(char_freq_dollar, word_freq_remove, word_freq_hp):
    inputArray = [char_freq_dollar, word_freq_remove, word_freq_hp]
    return clf.predict(inputArray)

# get some info about the resulting model
predictSpam.service.url
predictSpam.service.api_key

# and call it
predictSpam.service(1, 1, 1)