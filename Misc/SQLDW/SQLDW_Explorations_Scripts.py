# NYC Data wrangling using Python and Azure SQL Data Warehouse

#-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-#
#                   License Information                     #
#-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-#
# This sample IPython Notebook is shared by Microsoft under the MIT license.
# Please check the LICENSE.txt file in the directory where this Python script file is stored
# for license information and additional details.

#-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-#
#                      Prerequisites                        #
#-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-#
# Anaconda Python 2.7
# Or Python 2.7 and modules including pandas, numpy, matplotlib, time, pyodbc, tables
# Azure SQL Data Warehouse provisioned

#-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-#
#                      Background                           #
#-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-#
# This notebook demonstrates data exploration and feature generation
# using Python and SQL queries for data stored in Azure SQL Data Warehouse.
# We start with reading a sample of the data into a Pandas data frame and
# visualizing and exploring the data.
# We show how to use Python to execute SQL queries against the data
# and manipulate data directly within the Azure SQL Data Warehouse.

# This IPNB is accompanying material to the Azure Data Science in Action walkthrough document
# (https://azure.microsoft.com/en-us/documentation/articles/machine-learning-data-science-process-sqldw-walkthrough/)
# and uses the New York City Taxi dataset (http://www.andresmh.com/nyctaxitrips/).

#-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-#
#   Step 1: Read data in Pandas frame for visualizations    #
#-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-#
# We start with loading a sample of the data in a Pandas data frame and performing some explorations on the sample. 
# We join the Trip and Fare data and select the top 10000 rows of the dataset in a Pandas dataframe.
# We assume that the Trip and Fare tables have been created and loaded to tables in SQL Data Warehouse.
# If you haven't done this already please refer to the 'Load the data to SQL Data Warehouse' section of this walkthrough.

# Step 1.1. Import required packages in this experiment (no output)
import pandas as pd
from pandas import Series, DataFrame
import numpy as np
import matplotlib.pyplot as plt
from time import time
import pyodbc
import os
import tables
import time

# Step 1.2. Initialize Database Credentials (no output)
SERVER_NAME = '<server name>'
DATABASE_NAME = '<database name>'
USERID = '<user name>'
PASSWORD = '<password>'
DB_DRIVER = '<database driver>'

# Step 1.3. Create Data Warehouse Connection (no output)
CONNECTION_STRING = ';'.join([driver,server,database,uid,pwd, ';TDS_VERSION=7.3;Port=1433'])
print CONNECTION_STRING
conn = pyodbc.connect(CONNECTION_STRING)

# Step 1.4. Report number of rows and columns in table <nyctaxi_trip> (outputs numbers of records and columns in trip table)
nrows = pd.read_sql('''SELECT SUM(rows) FROM sys.partitions WHERE object_id = OBJECT_ID('<schemaname>.<nyctaxi_trip>')''', conn)
print 'Total number of rows = %d' % nrows.iloc[0,0]

ncols = pd.read_sql('''SELECT count(*) FROM information_schema.columns WHERE table_name = ('<nyctaxi_trip>') AND and table_schema = '<schemaname>'''', conn)
print 'Total number of columns = %d' % ncols.iloc[0,0]

# Step 1.5. Report number of rows and columns in table <nyctaxi_fare> (outputs numbers of records and columns in fare table)
nrows = pd.read_sql('''SELECT SUM(rows) FROM sys.partitions WHERE object_id = OBJECT_ID('<schemaname>.<nyctaxi_fare>')''', conn)
print 'Total number of rows = %d' % nrows.iloc[0,0]

ncols = pd.read_sql('''SELECT count(*) FROM information_schema.columns WHERE table_name = ('<nyctaxi_fare>') AND and table_schema = '<schemaname>''', conn)
print 'Total number of columns = %d' % ncols.iloc[0,0]

# Step 1.6 Read-in data from SQL Data Warehouse (outputs reading time and shape of data read in)
t0 = time.time()

#load only a small percentage of the joined data for some quick visuals
df1 = pd.read_sql('''select top 10000 t.*, f.payment_type, f.fare_amount, f.surcharge, f.mta_tax, 
      f.tolls_amount, f.total_amount, f.tip_amount 
      from <schemaname>.<nyctaxi_trip> t, <schemaname>.<nyctaxi_fare> f where datepart("mi",t.pickup_datetime)=0 and t.medallion = f.medallion 
      and t.hack_license = f.hack_license and t.pickup_datetime = f.pickup_datetime''', conn)

t1 = time.time()
print 'Time to read the sample table is %f seconds' % (t1-t0)

print 'Number of rows and columns retrieved = (%d, %d)' % (df1.shape[0], df1.shape[1])

# Step 1.7. Descriptive statistics of the data (outputs statistics of data)
# Now we can explore the sample data. We start with looking at descriptive statistics for trip distance:
df1['trip_distance'].describe()

# Step 1.8. Plot the box plot of trip_distance (outputs figures)
# Next we look at the box plot for trip distance to visualize quantiles
df1.boxplot(column='trip_distance',return_type='dict')

# Step 1.9. Plot the distribution of trip_distance (outputs figures)
fig = plt.figure()
ax1 = fig.add_subplot(1,2,1)
ax2 = fig.add_subplot(1,2,2)
df1['trip_distance'].plot(ax=ax1,kind='kde', style='b-')
df1['trip_distance'].hist(ax=ax2, bins=100, color='k')

# Step 1.10. Put the trip_distance to bins
trip_dist_bins = [0, 1, 2, 4, 10, 1000]
df1['trip_distance']
trip_dist_bin_id = pd.cut(df1['trip_distance'], trip_dist_bins)
trip_dist_bin_id

# Step 1.11. Plot the bar and line charts of the trip_distance in bins (outputs figures)
# The distribution of the trip distance values after binning looks like the following:
pd.Series(trip_dist_bin_id).value_counts()
# We can plot the above bin distribution in a bar or line plot as below
pd.Series(trip_dist_bin_id).value_counts().plot(kind='bar')
pd.Series(trip_dist_bin_id).value_counts().plot(kind='line')
# We can also use bar plots for visualizing the sum of passengers for each vendor as follows
vendor_passenger_sum = df1.groupby('vendor_id').passenger_count.sum()
print vendor_passenger_sum
vendor_passenger_sum.plot(kind='bar')

# Step 1.12. Plot the Scatter plot between trip_time_in_secs and trip_distance (output figures)
# to see whether there is any correlation between them
plt.scatter(df1['trip_time_in_secs'], df1['trip_distance'])
# To further drill down on the relationship we can plot distribution side by side
# with the scatter plot (while flipping independentand dependent variables) as follows
df1_2col = df1[['trip_time_in_secs','trip_distance']]
pd.scatter_matrix(df1_2col, diagonal='hist', color='b', alpha=0.7, hist_kwds={'bins':100})
# Similarly we can check the relationship between rate_code and trip_distance using a scatter plot
plt.scatter(df1['passenger_count'], df1['trip_distance'])

# Step 1.13. Calculate the correlation between trip_time_in_secs and trip_distance (outputs correlations between two columns)
# Pandas 'corr' function can be used to compute the correlation between trip_time_in_secs and trip_distance as follows:
df1[['trip_time_in_secs', 'trip_distance']].corr()

#-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-#
# Step 2: Exploring the Sampled Data in SQL Data Warehouse  #
#-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-#
# In this section we used a sampled table we pregenerated by joining Trip and Fare data and taking a sub-sample of the full dataset. 
# The sample data table named '<nyctaxi_sample>' has been created and the data is loaded when you run the PowerShell script.
# Step 2.1. Report number of rows and columns in the sampled table (outputs numbers of rows and columns in the sampled data table
nrows = pd.read_sql('''SELECT SUM(rows) FROM sys.partitions WHERE object_id = OBJECT_ID('<schemaname>.<nyctaxi_sample>')''', conn)
print 'Number of rows in sample = %d' % nrows.iloc[0,0]

ncols = pd.read_sql('''SELECT count(*) FROM information_schema.columns WHERE table_name = ('<nyctaxi_sample>') AND and table_schema = '<schemaname>''', conn)
print 'Number of columns in sample = %d' % ncols.iloc[0,0]

# Step 2.2. Check the tipped/not tipped distribution (outputs counts of trips in tipped/not tipped classes)
query = '''
        SELECT tipped, count(*) AS tip_freq
        FROM <schemaname>.<nyctaxi_sample>
        GROUP BY tipped
        '''

pd.read_sql(query, conn)

# Step 2.3. Check the tip class (tip_amount) distribution (outputs counts of trips in tip classes)
query = '''
        SELECT tip_class, count(*) AS tip_freq
        FROM <schemaname>.<nyctaxi_sample>
        GROUP BY tip_class
'''

tip_class_dist = pd.read_sql(query, conn)
tip_class_dist

# Step 2.4. Plot the tip distribution by class (outputs figures)
tip_class_dist['tip_freq'].plot(kind='bar')

# Step 2.5. Count the number of trips each day (outputs a data frame with count of trips in each day)
query = '''
        SELECT CONVERT(date, dropoff_datetime) as date, count(*) as c 
        from <schemaname>.<nyctaxi_sample> 
        group by CONVERT(date, dropoff_datetime)
        '''
pd.read_sql(query,conn)

# Step 2.6. Count the number of trips per each medallion (outputs a data frame with count of trips by each medallion ID)
query = '''select medallion,count(*) as c from <schemaname>.<nyctaxi_sample> group by medallion'''
pd.read_sql(query,conn)

# Step 2.7. Count the number of trips per each medallion and license (outputs a data frame)
query = '''select medallion, hack_license,count(*) from <schemaname>.<nyctaxi_sample> group by medallion, hack_license'''
pd.read_sql(query,conn)

# Step 2.8. Count the number of trips by trip_time_in_secs (outputs a data frame)
query = '''select trip_time_in_secs, count(*) from <schemaname>.<nyctaxi_sample> group by trip_time_in_secs order by count(*) desc'''
pd.read_sql(query,conn)

# Step 2.9. Count the number of trips by trip_distance (outputs a data frame)
query = '''select floor(trip_distance/5)*5 as tripbin, count(*) from <schemaname>.<nyctaxi_sample> group by floor(trip_distance/5)*5 order by count(*) desc'''
pd.read_sql(query,conn)

# Step 2.10. Count the number of trips by payment type (outputs a data frame)
query = '''select payment_type,count(*) from <schemaname>.<nyctaxi_sample> group by payment_type'''
pd.read_sql(query,conn)

# Step 2.11. Read the top 10 observations from the sample table (outputs a data frame)
query = '''select TOP 10 * from <schemaname>.<nyctaxi_sample>'''
pd.read_sql(query,conn)


