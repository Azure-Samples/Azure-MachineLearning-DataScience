#!/home/lsun/anaconda/bin/python
# In this script, we compute the precision for the returned top-k 
# 
#
# ========== Version Information =====
# This _Arg version is based on recPrecision_v2.2.py (v2.2 version internally) 
#==================

import sys
import argparse

#================ Begin of Parameter Settings ==============
parser = argparse.ArgumentParser()
parser.add_argument("-t", "--testFile", help = "the file storing the test data set (required)")
parser.add_argument("-p", "--predictFile", help = "the file storing the prediction (required)")
parser.add_argument("-k", "--k", type = int, help = "the number of top items to be evaluated (default is 5)")
parser.add_argument("--testFileHeader", help = "if the test file has header or not (default is no)")
parser.add_argument("--predictFileHeader", help = "if the predict file has header or not (default is no)")
parser.add_argument("--itemIdIgnoreCase", help = "if we ignore case in comparing itemId (default is yes)")

def checkBoolParam(paramName, defaultValue):
    try:
        paramName = int(paramName)
    except ValueError:
        paramName = defaultValue
    if paramName == 0:
        paramName = False
    else:
        paramName = True
    return(paramName)    

def checkIntParam(paramName, defaultValue):
    try:
        paramName = int(paramName)
    except ValueError:
        paramName = defaultValue
    if paramName < 0:
        paramName = 0
    return(paramName)

# Parse input parameters
args = parser.parse_args()
testFile = args.testFile
predictFile = args.predictFile
if args.k != None:
    k = checkIntParam(args.k, 5)
else:
    k = 5
if args.testFileHeader != None:
    testFileHeader = checkBoolParam(args.testFileHeader, False)
else:
    testFileHeader = False
if args.predictFileHeader != None:
    predictFileHeader = checkBoolParam(args.predictFileHeader, False)
else:
    predictFileHeader = False
if args.itemIdIgnoreCase != None:
    itemIdIgnoreCase = checkBoolParam(args.itemIdIgnoreCase, True)
else:
    itemIdIgnoreCase = True
#================ End of Parameter Settings ==============


# For some users, we may not have k returned items.
# If filter_option=True, we will not consider these users;
# If filter_option=False, we will consider these users in precision calculation.
filter_option = False

# Step 1. Read the test groundtruth data set
f_test_in = open(testFile)
if testFileHeader:
    line = f_test_in.readline()
line = f_test_in.readline().strip()
D_test = {}
while line:
    fs = line.split(',')
    userId = fs[0]
    itemId = fs[1]
    if itemIdIgnoreCase:
        itemId = itemId.upper()
    
    if userId not in D_test:
        D_test[userId] = []
    D_test[userId].append(itemId)
    
    line = f_test_in.readline().strip()
f_test_in.close()

# Step 2. Read the prediction file
f_predict_in = open(predictFile)
if predictFileHeader:
    line = f_predict_in.readline()
line = f_predict_in.readline().strip()
D_predict = {}
while line:
    fs = line.split(',')
    userId = fs[0]
    itemId_list = fs[1:]
    # preprocess of item Id
    if itemIdIgnoreCase:
        itemId_list = [itemId.upper() for itemId in itemId_list]
    # filter out empty recommendation
    itemId_list2 = [itemId for itemId in itemId_list if (itemId != '' and itemId != '""')]
    D_predict[userId] = itemId_list2
    
    line = f_predict_in.readline().strip()
f_predict_in.close()


# Step 3. Compute the precision@k
def listOverlap(list1, list2):
    # This function computes the number of overlapped items in two lists
    return list(set(list1) & set(list2))

precision_sum = 0.0
user_counted_num = 0
userId_not_rated = []
print_count = 0

if filter_option:
    for userId in D_test:
        if userId not in D_predict:
            userId_not_rated.append(userId)
        else:
            itemId_list = D_predict[userId]
            if len(itemId_list) < k:
                userId_not_rated.append(userId)
                #print 'skip userId = %s'%userId
            else:
                g_test = D_test[userId]
                p_test = D_predict[userId][:k]
                pg_test = listOverlap(g_test, p_test)
                #p_u = len(pg_test) / float(k)
                if(len(pg_test)>0):
                    p_u = 1.0
                else:
                    p_u = 0.0
                precision_sum += p_u
                user_counted_num += 1
    
else:
    # in this case, we don't filter empty recommended item.
    for userId in D_test:
        if userId not in D_predict:
            userId_not_rated.append(userId)
        else:
            g_test = D_test[userId]
            p_test = D_predict[userId][:k]
            pg_test = listOverlap(g_test, p_test)
            #p_u = len(pg_test) / float(k)
            if len(pg_test)>0:
                p_u = 1.0
            else:
                p_u = 0.0
            precision_sum += p_u
            user_counted_num += 1
precision_avg = precision_sum / float(user_counted_num)

fout = sys.stdout
s = 'k=%d\n'%k
fout.write(s)
s = 'precision_avg = %f\n'%precision_avg
fout.write(s)
s = 'counted user number = %d\n'%user_counted_num        
fout.write(s)
# users not considered in computation are stored in userId_not_rated, which can be used in the future
