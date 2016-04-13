# This Azure function is triggered based on a Blob being created or updated
# When this event is triggered we will call the Spark Livy Batch endpoint and execute the Python script ConsumeGBNYCReg.py within Spark cluster to score a specific public blob. This python script is uploaded to Spark cluster first 
# TODO: The ConsumeGBNYCReg.py taking as argument the file to score 

import os

# Python 'requests' library would be way more convenient. Howver it is not installed by default in Azure Functions currently. So use older http libraries
import httplib, urllib, base64

#REPLACE VALUE WITH ONES FOR YOUR SPARK CLUSTER
host = '<spark cluster name>.azurehdinsight.net:443'
username='<username>'
password='<password>'

conn = httplib.HTTPSConnection(host)
auth = base64.encodestring('%s:%s' % (username, password)).replace('\n', '')
headers = {'Content-Type': 'application/json', 'Authorization': 'Basic %s' % auth}

# Specify the Python script to run on the Spark cluster in the "file" parameter of the JSON post request body
r=conn.request("POST", '/livy/batches', '{"file": "wasb:///example/python/ConsumeGBNYCReg.py"}', headers )
response = conn.getresponse().read()
print(response)
conn.close()




