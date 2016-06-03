
# coding: utf-8

# ### After data has been processed in U-SQL and stored in Azure Blob, you can use Python to build machine learning models and web service API following the steps below:
# 
# - Step 0. Import packages 
# - Step 1. Read in the Data from blob
# - Step 2. Check basic statistics of this data set
# - Step 3. Missing Value Handling
# - Step 4. Data Exploration in a single variable
# - Step 5. Explore the relationship between two or more columns
# - Step 6. Feature engineering
# - Step 7. Build Machine Learning Models
# - Step 8. Build Web Service API and consume it in Python
# 

# ###Step 0. import  packages

# In[2]:

import pandas as pd
from pandas import Series, DataFrame
import numpy as np
import matplotlib.pyplot as plt
from time import time
import pyodbc
import os
from azure.storage.blob import BlobService
import tables
import time
import zipfile
import random
import sklearn
from sklearn.linear_model import LogisticRegression
from sklearn.cross_validation import train_test_split
from sklearn import metrics
from __future__ import division
from sklearn import linear_model
from azureml import services


# ###Step 1. Read in the Data from blob

# In[64]:

#Connection String
CONTAINERNAME = 'test1'
STORAGEACCOUNTNAME = 'weigstoragefordsvm'
STORAGEACCOUNTKEY = 'FUyNCM83pY4K2srBfZv4yDr6ru7d+BfbmHPPtucqS7EIgvUSQBG4zPkznpCuClWVOMitAQXG3aJFbvuD7mBkhQ=='
BLOBNAME = 'demo_ex_9_stratified_1_1000_copy.csv'

blob_service = BlobService(account_name=STORAGEACCOUNTNAME,account_key=STORAGEACCOUNTKEY)

#Read in as text
t1 = time.time()
data = blob_service.get_blob_to_text(CONTAINERNAME,BLOBNAME).split("\n")
t2 = time.time()
print(("It takes %s seconds to read in "+BLOBNAME) % (t2 - t1))

#Add column names and separate columns
colnames = ['medallion','hack_license','vendor_id','rate_code','store_and_fwd_flag','pickup_datetime','dropoff_datetime',
'passenger_count','trip_time_in_secs','trip_distance','pickup_longitude','pickup_latitude','dropoff_longitude','dropoff_latitude',
'payment_type', 'fare_amount', 'surcharge', 'mta_tax', 'tolls_amount',  'total_amount', 'tip_amount', 'tipped', 'tip_class', 'rownum']

df1 = pd.DataFrame([sub.split(",") for sub in data], columns = colnames)

#Change some columns to numeric
cols_2_float = ['trip_time_in_secs','pickup_longitude','pickup_latitude','dropoff_longitude','dropoff_latitude',
'fare_amount', 'surcharge','mta_tax','tolls_amount','total_amount','tip_amount', 'passenger_count','trip_distance'
,'tipped','tip_class','rownum']
for col in cols_2_float:
    df1[col] = df1[col].astype(float)


# ###Step 2. Check basic statistics of this data set

# In[32]:

#Check the data frame
print df1.head(5)
print df1.tail(5)
print df1.shape


# In[66]:

#The last row of data is na, remove it
df1 = df1.iloc[0:len(df1)-2,:]

#Remove the quote in some columns
df1.medallion = df1.medallion.str.replace('"','')
df1.hack_license = df1.hack_license.str.replace('"','')
df1.vendor_id = df1.vendor_id.str.replace('"','')
df1.rate_code = df1.rate_code.str.replace('"','')
df1.store_and_fwd_flag = df1.store_and_fwd_flag.str.replace('"','')
df1.payment_type = df1.payment_type.str.replace('"','')

print 'the size of the data is: %d rows and  %d columns' % df1.shape


# In[87]:

#Check several columns in row 101
df1.ix[101, ['vendor_id', 'passenger_count', 'trip_time_in_secs', 'trip_distance']]


# In[88]:

# Show column names and types of the data frame
for col in df1.columns:
    print df1[col].name, ':\t', df1[col].dtype


# In[10]:

#Check the number of valid values (non-NA) for each column
cnts = df1.count()
print cnts


# In[90]:

#Check the number of missing values for each column
miss_num = df1.shape[0] - df1.count()
print miss_num


# In[91]:

#Check the basic statistics for all columns (only applied to numeric columns)
df1.describe()


# ###Step 3. Missing Value Handling

# In[67]:

#Missing value handling for store_and_fwd_flag
#First check all possible values of store_and_fwd_flg
df1['store_and_fwd_flag'].value_counts()


# In[62]:

df1.head()


# In[58]:

df2 = df1.replace('', np.nan, regex=True)


# In[70]:

df2.shape


# In[71]:

#Drop rows containing missing values
df1_noNA = df2.dropna()
df1_noNA.shape


# In[59]:

df2.ix[990:1000,]


# In[73]:

#Set all missing values of store_and_fwd_flg as 'M'
df3 = df2.fillna({'store_and_fwd_flag':'M'})
df3.ix[990:1000,]


# In[74]:

df3.shape


# In[75]:

df3['store_and_fwd_flag'].value_counts()


# In[79]:

df2['store_and_fwd_flag'].mode()[0]


# In[80]:

#Set all missing values of store_and_fwd_flg as the mode of this column
df4 = df2.fillna({'store_and_fwd_flag':df2['store_and_fwd_flag'].mode()[0]})
df4.ix[990:1000,]


# In[12]:

#Use "M" as the filling value and use inplace option to change df1 directly
df1.fillna({'store_and_fwd_flag':'M'}, inplace=True)
df1['store_and_fwd_flag'].value_counts()


# ###Step 4. Data Exploration in a single variable

# In[97]:

#Check categorical variable vendor_id
vendor_id_levels = df1['vendor_id'].unique()
vendor_id_levels


# In[98]:

#Show the distribution of different levels
df1['vendor_id'].value_counts()


# In[99]:

# Show the number of different levels and without sorting levels
pd.value_counts(df1['vendor_id'], sort=False)


# In[100]:

#Show the mode of vendor_id
df1['vendor_id'].mode()


# In[101]:

#Show the distribution in bar chart
df1['vendor_id'].value_counts().plot(kind='bar')


# In[102]:

#Check categorical variable rate_code
df1['rate_code'].value_counts()


# In[103]:

#Show the mode of rate_code
df1['rate_code'].mode()


# In[104]:

# Show the corresponding bar chart
df1['rate_code'].value_counts().plot(kind='bar')


# In[105]:

#Show the bar chart in log scale
np.log(df1['rate_code'].value_counts()).plot(kind='bar')


# In[106]:

# Check numeric variable passenger_count
df1['passenger_count'].describe()
df1['passenger_count'].value_counts()


# In[107]:

#Plot the histogram of the passenger_count (after log scale)
np.log(df1['passenger_count']+1).hist(bins=50)


# In[108]:

#Check numeric variable trip_time_in_secs
df1['trip_time_in_secs'].describe()


# In[109]:

#Plot the histogram of trip_time_in_secs
df1['trip_time_in_secs'].hist(bins=50)
np.log(df1['trip_time_in_secs']+1).hist(bins=50)


# In[110]:

#Plot the kernel density estimate of trip_time_in_secs
#Since plotting the kernel density estimate is relatively slow, we sample the data to draw it; you can change the sampling ratio as necessary.
sample_ratio = 0.01
sample_size = np.round(df1.shape[0] * sample_ratio)
sample_rows = np.random.choice(df1.index.values, sample_size)
df1_sample = df1.ix[sample_rows]
df1_sample.shape


# In[111]:

#Draw the kernel density estimate for the column trip_time_in_secs in df1_sample
df1_sample['trip_time_in_secs'].plot(kind='kde', style='b-')
df1['trip_time_in_secs'].plot(kind='kde', style='b-')


# In[112]:

#Show histogram and kernel density estimate plot simultaneously
df1_sample['trip_time_in_secs'].hist(bins=50, color='k', normed=True)
df1_sample['trip_time_in_secs'].plot(kind='kde', style='b-')


# In[113]:

#Or we can show two plots together, but each one is a separate subplot
fig = plt.figure()
ax1 = fig.add_subplot(1,2,1)
ax2 = fig.add_subplot(1,2,2)
df1_sample['trip_time_in_secs'].plot(ax=ax1,kind='kde', style='b-')
df1_sample['trip_time_in_secs'].hist(ax=ax2, bins=50, color='k')


# In[114]:

#Compare histograms of df1 and df1_sample
fig = plt.figure()
ax1 = fig.add_subplot(1,2,1)
ax2 = fig.add_subplot(1,2,2)
df1['trip_time_in_secs'].hist(ax=ax1, bins=50, color='b')
df1_sample['trip_time_in_secs'].hist(ax=ax2, bins=50, color='k')


# In[115]:

#In the following we show sum basic functions to compute statistics

print(df1['trip_time_in_secs'].mean())
print(df1['trip_time_in_secs'].median())
print(df1['trip_time_in_secs'].std())
print(df1['trip_time_in_secs'].skew())
print(df1['trip_time_in_secs'].sum())
print(df1['trip_time_in_secs'].var())
print(df1['trip_time_in_secs'].quantile(0.25))
print(df1['trip_time_in_secs'].quantile(0.5))
df1['trip_time_in_secs'].describe()


# In[116]:

#Check numeric variable trip_distance
df1['trip_distance'].describe()


# In[117]:

#Draw boxplot
df1.boxplot(column='trip_distance',return_type='dict')


# In[118]:

#Show the distribution of trip_distance by showing two plots together. We also use df1_sample since kde plot drawing ins slow
fig = plt.figure()
ax1 = fig.add_subplot(1,2,1)
ax2 = fig.add_subplot(1,2,2)
df1_sample['trip_distance'].plot(ax=ax1,kind='kde', style='b-')
df1_sample['trip_distance'].hist(ax=ax2, bins=100, color='k')


# In[119]:

#Calculate the number of trip_distance in different groups
trip_dist_bins = [0, 1, 2, 4, 10, 1000]
df1['trip_distance']
trip_dist_bin_id = pd.cut(df1['trip_distance'], trip_dist_bins)
trip_dist_bin_id
trip_dist_bin_id.value_counts()
trip_dist_bin_id.value_counts().plot(kind='bar')
trip_dist_bin_id.value_counts().plot(kind='line')


# ###Step 5. Explore the relationship between two or more columns

# In[120]:

#Explore the relationship between trip_time_in_secs and trip_distance using scatter plot
plt.scatter(df1['trip_time_in_secs'], df1['trip_distance'])


# In[121]:

#Plot histograms and scatter plots simultaneously
df1_2col = df1[['trip_time_in_secs','trip_distance']]
pd.scatter_matrix(df1_2col, diagonal='hist', color='b', alpha=0.7, hist_kwds={'bins':100})


# In[122]:

#Replace the diagonal plots as kde on the sampled data set (we do not do it on the original data data as kde plot drawing is relatively slow)
df1_sample_2col = df1_sample[['trip_time_in_secs','trip_distance']]
pd.scatter_matrix(df1_sample_2col, diagonal='kde', color='b', alpha=0.7)


# In[123]:

#Explore the relationship between rate_code and trip_distance using scatter plot
plt.scatter(df1['passenger_count'], df1['trip_distance'])


# In[124]:

#Explore multiple columns simultaneously using scatter plot and histogram and kde
df1_sample_3col = df1_sample[['passenger_count', 'trip_time_in_secs', 'trip_distance']]
pd.scatter_matrix(df1_sample_3col, diagonal='hist', color='r', alpha=0.7, hist_kwds={'bins':100})
pd.scatter_matrix(df1_sample_3col, diagonal='kde', color='r', alpha=0.7)


# In[125]:

#Compute the correlation between trip_time_in_secs and trip_distance
print df1[['trip_time_in_secs', 'trip_distance']].corr()


# In[126]:

#Compute the correlation involving 3 variables: trip_time_in_secs, trip_distance, and passenger_count
print df1[['trip_time_in_secs', 'trip_distance', 'passenger_count']].corr()


# In[127]:

#Compute the covariance between trip_time_in_secs and trip_distance
print df1[['trip_time_in_secs', 'trip_distance']].cov()


# In[128]:

#Compute the covariance involving 3 variables
print df1[['trip_time_in_secs', 'trip_distance', 'passenger_count']].cov()


# In[130]:

#Explore the relationship between trip_time_in_secs and passenger_count
df1['passenger_count'].value_counts()
df1.boxplot(column='trip_time_in_secs', by='passenger_count')


# In[131]:

#Explore the relationship between trip_distance and passenger_count
df1.boxplot(column='trip_distance', by='passenger_count')


# In[132]:

#Check the sum of passengers for each vendor
vendor_passenger_sum = df1.groupby('vendor_id').passenger_count.sum()
print vendor_passenger_sum
vendor_passenger_sum.plot(kind='bar')


# ###Step 6. Feature engineering

# In[76]:

#Convert categorical features to a sequence of dummy features
df1['rate_code'].value_counts()

df1_rate_code_dummy = pd.get_dummies(df1['rate_code'], prefix='rate_code_dummy')
df1_rate_code_dummy.head()
#df1['rate_code'].head()


# In[134]:

#Join the dummy variables back to the original data frame
df1_with_dummy = df1.join(df1_rate_code_dummy)
df1_with_dummy


# In[135]:

#Remove the original column rate_code in df1_with_dummy
df1_with_dummy.drop('rate_code', axis=1, inplace=True)
df1_with_dummy.head(5)


# In[136]:

#Create bins based on trip_distance
trip_dist_bins = [0, 1, 2, 4, 10, 40]
trip_dist_bin_id = pd.cut(df1['trip_distance'], trip_dist_bins)
trip_dist_bin_id.head(5)


# In[137]:

#Convert binning to a sequence of boolean variables
df1_bin_bool = pd.get_dummies(trip_dist_bin_id, prefix='trip_dist')
df1_bin_bool.head(5)


# In[138]:

#Join the dummy variables back to the original data frame
df1_with_bin_bool = df1.join(df1_bin_bool)
df1_with_bin_bool.head(5)


# ###Step 7. Build Machine Learning Models
# Model 1: Binary Classification: Tipped or Not
# Model 2: Multiclass Classification: Tipped_Class
# Model 3: Linear Regression: Tip_Amount

# In[139]:

#Model 1: Binary classification

#check some candidate predictors
print df1['payment_type'].describe()
print df1['payment_type'].value_counts()
print df1['trip_distance'].describe()


# In[140]:

##dummify payment_type
df1_payment_type_dummy = pd.get_dummies(df1['payment_type'], prefix='payment_type_dummy')
df1_vendor_id_dummy = pd.get_dummies(df1['vendor_id'], prefix='vendor_id_dummy')


# In[141]:

##create data frame for the modeling
cols_to_keep = ['tipped', 'trip_distance', 'passenger_count']
data = df1[cols_to_keep].join([df1_payment_type_dummy,df1_vendor_id_dummy])

X = data.iloc[:,1:]
Y = data.tipped


# In[142]:

#Training and testing 60-40 split
X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size=0.4, random_state=0)


# In[143]:

#Logistic Regression in traing set
model = LogisticRegression()
logit_fit = model.fit(X_train, Y_train)
print ('Coefficients: \n', logit_fit.coef_)
Y_train_pred = logit_fit.predict(X_train)


# In[144]:

#Score testing data set
Y_test_pred = logit_fit.predict(X_test)


# In[145]:

#Evaluation metrics
fpr_train, tpr_train, thresholds_train = metrics.roc_curve(Y_train, Y_train_pred)
print fpr_train, tpr_train, thresholds_train

fpr_test, tpr_test, thresholds_test = metrics.roc_curve(Y_test, Y_test_pred) 
print fpr_test, tpr_test, thresholds_test

#AUC
print metrics.auc(fpr_train,tpr_train)
print metrics.auc(fpr_test,tpr_test)

#Confusion Matrix
print metrics.confusion_matrix(Y_train,Y_train_pred)
print metrics.confusion_matrix(Y_test,Y_test_pred)


# In[146]:

#Model 2: Multiclass classification
##create data frame for the modeling
cols_to_keep = ['tip_class', 'trip_distance', 'passenger_count']
data = df1[cols_to_keep].join([df1_payment_type_dummy,df1_vendor_id_dummy])

X = data.iloc[:,1:]
Y = data.tip_class

#Training and testing 60-40 split
X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size=0.4, random_state=0)

model = LogisticRegression()
mlogit_fit = model.fit(X_train, Y_train)
print ('Coefficients: \n', mlogit_fit.coef_)
Y_train_pred = mlogit_fit.predict(X_train)

#Score testing data set
Y_test_pred = mlogit_fit.predict(X_test)

#Evaluation metrics
accuracy_train = sum(Y_train == Y_train_pred)/X_train.shape[0]
accuracy_test = sum(Y_test == Y_test_pred)/X_test.shape[0]
print accuracy_train,accuracy_test

#Confusion Matrix
print metrics.confusion_matrix(Y_train,Y_train_pred)
print metrics.confusion_matrix(Y_test,Y_test_pred)


# In[147]:

#Model 3: Regression Model
##create data frame for the modeling
cols_to_keep = ['tip_amount', 'trip_distance', 'passenger_count']
data = df1[cols_to_keep].join([df1_payment_type_dummy,df1_vendor_id_dummy])

X = data.iloc[:,1:]
Y = data.tip_amount

#Training and testing 60-40 split
X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size=0.4, random_state=0)


model = linear_model.LinearRegression()
lm_fit = model.fit(X_train, Y_train)
print ('Coefficients: \n', lm_fit.coef_)
Y_train_pred = lm_fit.predict(X_train)

#Score testing data set
Y_test_pred = lm_fit.predict(X_test)

#Evaluation Matrics
MSE_train = np.mean((Y_train_pred - Y_train)**2)
MSE_test = np.mean((Y_test_pred - Y_test)**2)
R_Sq_train = lm_fit.score(X_train,Y_train)
R_Sq_test = lm_fit.score(X_test,Y_test)

print ('Mean Square Error in training: %.4f' % MSE_train)
print ('Mean Square Error in testing: %.4f' % MSE_test)

print ('R-Square in training: %.4f' % R_Sq_train)
print ('R-Square in testing: %.4f' % R_Sq_test)


# ###Step 8. Build Web Service API and consume it in Python
# Here we use the binary logistic model as an example
# Make sure the scikit-learn version in your local machine is 0.15.1

# In[148]:

#Find your workspaca credentials from Azure ML studio settings
workspaceid = '5ef876a4f3ca460292afcd629808b823'
auth_token = '810080c867b84e90be61bdf9b782dcbc'

#Create Web Service
@services.publish(workspaceid, auth_token) 
@services.types(trip_distance = float, passenger_count = float, payment_type_dummy_CRD = float, payment_type_dummy_CSH=float, payment_type_dummy_DIS = float, payment_type_dummy_NOC = float, payment_type_dummy_UNK = float, vendor_id_dummy_CMT = float, vendor_id_dummy_VTS = float)
@services.returns(int) #0, or 1
def predictNYCTAXI(trip_distance, passenger_count, payment_type_dummy_CRD, payment_type_dummy_CSH,payment_type_dummy_DIS, payment_type_dummy_NOC, payment_type_dummy_UNK, vendor_id_dummy_CMT, vendor_id_dummy_VTS ):
    inputArray = [trip_distance, passenger_count, payment_type_dummy_CRD, payment_type_dummy_CSH, payment_type_dummy_DIS, payment_type_dummy_NOC, payment_type_dummy_UNK, vendor_id_dummy_CMT, vendor_id_dummy_VTS]
    return logit_fit.predict(inputArray)

#Get web service credentials
url = predictNYCTAXI.service.url
api_key =  predictNYCTAXI.service.api_key

print url
print api_key

@services.service(url, api_key)
@services.types(trip_distance = float, passenger_count = float, payment_type_dummy_CRD = float, payment_type_dummy_CSH=float,payment_type_dummy_DIS = float, payment_type_dummy_NOC = float, payment_type_dummy_UNK = float, vendor_id_dummy_CMT = float, vendor_id_dummy_VTS = float)
@services.returns(float)
def NYCTAXIPredictor(trip_distance, passenger_count, payment_type_dummy_CRD, payment_type_dummy_CSH,payment_type_dummy_DIS, payment_type_dummy_NOC, payment_type_dummy_UNK, vendor_id_dummy_CMT, vendor_id_dummy_VTS ):
    pass


# In[13]:

#Call Web service API
#You have to wait 5-10 seconds, some latency here
NYCTAXIPredictor(1,2,1,0,0,0,0,0,1)

