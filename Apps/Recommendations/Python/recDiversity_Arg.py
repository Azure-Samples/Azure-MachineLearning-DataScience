#!/home/lsun/anaconda/bin/python
# In this script, we compute the diversity of the recommended results.
# Input description:
# 1. predictFile: The recommendation results for test data set. Format:
#    userId,item1,item2,...,itemN
# 2. trainFile or trainHistFile: The item historgram in the training data set. 
#    Format of trainHistFile:
#    itemId,Freq
# Freq is the number of time itemId appears in the training data set
#    Format of trainFile:
#    userId,itemId,***
# We only require the first 2 columns are userId nd itemId, respectively.
# If the raw file is provided, you need to set f_input2_isRaw to be True
# Additional controlling parameters:
# 0. outputRow: it controls the output format. output_row=True, it will outputs a types of 
# output in a row; otherwise in a column.
# 1. if input files contain header or not.
# 2. itemIdIgnoreCase: if we ignore case when comparing itemId.
# 3. topK: in some cases, more recomendations are returned, but we are only interested in 
# topK items.
# 4. n_bin: number of bins in considering the items in training data set
# Output:
# 1. The number of unique items in test set
# 2. The percentage of (user, item) in the test set in the bins of items. The bins
# are determined by the histogram of items in the training data set. 
# For example, we need to compute the percentage of (user, item) in the test set
# where item is the top 10% popular items. 
# We also provide statistics for 50%, 0-90%, 91-100%. 
# Note that the output is directed to sys.stdout
# The default output format is in a row (but we provide the output in multiple rows by setting
# output_row = False)
# 
# ========== Version Information =====
# This _Arg version is based on recDiversity_v2.2.py (v2.2 version internally) 
#==================

import sys
import argparse
import numpy as np

#================ Begin of Parameter Settings ==============
parser = argparse.ArgumentParser()
parser.add_argument("-t", "--trainFile", help = "the file storing the training data set")
parser.add_argument("-s", "--trainHistFile", help = "the file storing the histogram of item appearance in the training file")
parser.add_argument("-p", "--predictFile", help = "the file storing the prediction")
parser.add_argument("-k", "--k", type = int, help = "the number of top items to be evaluated (default is 5)")
parser.add_argument("-n", "--n_bin", type = int, help = "the number of bins in computing diversity (default is 10)")
parser.add_argument("-o", "--outputRow", type = int, help = "if the output will in row format (default is yes)")

parser.add_argument("--trainFileHeader", help = "if the training file has header or not (default is no)")
parser.add_argument("--trainHistFileHeader", help = "if the item histgrom file from the training set has header or not (default is no)")
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
predictFile = args.predictFile
trainFile = args.trainFile
trainHistFile = args.trainHistFile
if args.trainHistFile == None:
    trainIsRaw = True
else:
    trainIsRaw = False

if args.k != None:
    k = checkIntParam(args.k, 5)
else:
    k = 5
if args.n_bin != None:
    n_bin = checkIntParam(args.n_bin, 10)
else:
    n_bin = 10    
if args.trainFileHeader != None:
    trainFileHeader = checkBoolParam(args.trainFileHeader, False)
else:
    trainFileHeader = False
if args.trainHistFileHeader != None:
    trainHistFileHeader = checkBoolParam(args.trainHistFileHeader, False)
else:
    trainHistFileHeader = False
if args.predictFileHeader != None:
    predictFileHeader = checkBoolParam(args.predictFileHeader, False)
else:
    predictFileHeader = False
if args.itemIdIgnoreCase != None:
    itemIdIgnoreCase = checkBoolParam(args.itemIdIgnoreCase, True)
else:
    itemIdIgnoreCase = True
if args.outputRow != None:
    outputRow = checkBoolParam(args.outputRow, True)
else:
    outputRow = True
    
if trainIsRaw:
    trainInputHeader = trainFileHeader
    trainInput = trainFile
else:
    trainInputHeader = trainHistFileHeader
    trainInput = trainHistFile
topK = k    

s = 'trainIsRaw = ' + str(trainIsRaw)
print(s)
#================ End of Parameter Settings ==============

# Read the training item histogram file and save it in a dictionary
D_train_item = {}
fin2 = open(trainInput)
line = fin2.readline().strip()
if trainInputHeader:
    line = fin2.readline().strip()

while line:
    if trainIsRaw:
        fs = line.split(',')
        itemId = fs[1]
        if itemIdIgnoreCase:
            itemId = itemId.upper()
        
        if itemId not in D_train_item:
            D_train_item[itemId] = 1
        else:
            D_train_item[itemId] = D_train_item[itemId] + 1
    else:
        fs = line.split(',')
        itemId = fs[0]
        if itemIdIgnoreCase:
            itemId = itemId.upper()
        
        itemFreq = int(fs[1])
        D_train_item[itemId] = itemFreq
     
    line = fin2.readline().strip()
fin2.close()

# Divide the histogram into n_bin bins
sorted_item_freq = sorted(D_train_item.values())
# in this list, we store the maximum value
bin_max_list = [0 for i in range(n_bin)]
item_total = len(sorted_item_freq)
bin_size = item_total / n_bin
for i in range(n_bin - 1):
    bin_max_list[i] = sorted_item_freq[bin_size * (i+1) - 1]
bin_max_list[n_bin-1] = sorted_item_freq[len(sorted_item_freq)-1]
# Compute the 91%, 92%, ..., 99%, 100% percentiles
bin_max_list_90p = [0 for i in range(10)]
for i in range(9):
    bin_max_list_90p[i] = np.percentile(sorted_item_freq, 91 + i)
bin_max_list_90p[9] = sorted_item_freq[len(sorted_item_freq)-1]
# Compute the 90% and 50% percentiles
if n_bin == 10:
    bin_max_90p = bin_max_list[n_bin-2]
    bin_max_50p = bin_max_list[4]
else:
    bin_max_90p = np.percentile(sorted_item_freq, 90)
    bin_max_50p = np.percentile(sorted_item_freq, 50)

'''
print 'bin_max_list = '
print bin_max_list
print 'bin_max_list_90p = '
print bin_max_list_90p
print 'bin_max_90p = %f'%bin_max_90p
print 'bin_max_50p = %f'%bin_max_50p
'''
    
# In this function, we compute bin_id based on bin_max_list and the value
def getBinId(bin_max_list, v):
    bin_id = -1
    for i in range(len(bin_max_list)):
        if v <= bin_max_list[i]:
            bin_id = i
            break
    return(bin_id)

# Read the test file, and compute the corresponding statistics
D_test_item = {}
userItemHist = [0 for i in range(n_bin)]
userItemHist90p = [0 for i in range(10)]
userItemHist_less50p = 0
userItemHist_greater50p = 0
userItemHist_less90p = 0

fin1 = open(predictFile)
line = fin1.readline().strip()
if predictFileHeader:
    line = fin1.readline().strip()
while line:
    fs = line.split(',')
    userId = fs[0]
    itemList = fs[1:] 
    # preprocess of itemList
    if len(itemList)>topK:
        itemList = itemList[:topK]
    if itemIdIgnoreCase:
        itemList = [itemId.upper() for itemId in itemList]
    
    for itemId in itemList:
        if itemId not in D_test_item:
            D_test_item[itemId] = 1    
    # consider the combination (userId, itemId)
    for itemId in itemList:
        item_freq = D_train_item.get(itemId, 0)
        bin_id = getBinId(bin_max_list, item_freq)
        userItemHist[bin_id] = userItemHist[bin_id] + 1
        
        # for 91-100 percentile
        if item_freq>bin_max_90p:
            bin_id90p = getBinId(bin_max_list_90p, item_freq)
            userItemHist90p[bin_id90p] = userItemHist90p[bin_id90p] + 1
        else:
            # for 90 percentile
            userItemHist_less90p += 1
        
        # for 50 percentile only
        if item_freq <= bin_max_50p:
            userItemHist_less50p += 1
        else:
            userItemHist_greater50p += 1
        
        
    line = fin1.readline().strip()
fin1.close()


'''
print 'userItemHist = '
print userItemHist
print 'userItemHist90p = '
print userItemHist90p
'''

# print out the computed statistics
#fout = open(f_path + f_output, 'w')
fout = sys.stdout
s = 'The number of unique items in the test set is %d\n'%len(D_test_item.keys())
fout.write(s)
s = 'The distribution of (userId, itemId):\n'
fout.write(s)


if outputRow:
    # print percentage range row
    s = 'percentage_range'
    for i in range(n_bin):
        percentage_i_left = 100 / float(n_bin) * i
        percentage_i_right = 100 / float(n_bin) * (i + 1)
        percentage_s = str(percentage_i_left) + '-' + str(percentage_i_right)
        s = s + ',' + percentage_s
    s = s + ',0-90'    
    for i in range(len(userItemHist90p)):
        percentage_i_left = 90 + i
        percentage_i_right = 91 + i
        percentage_s = str(percentage_i_left) + '-' + str(percentage_i_right)
        s = s + ',' + percentage_s
    s = s + ',0-50,51-100\n' 
    fout.write(s)
    # print the upper bound row
    s = 'bin_max_item_freq'
    for i in range(n_bin):
        s = s + ',' + str(bin_max_list[i])
    s = s + ',' + str(bin_max_90p)
    for i in range(len(userItemHist90p)):
        s = s + ',' + str(bin_max_list_90p[i])
    s = s + ',' + str(bin_max_50p) + ',' + str(bin_max_list[n_bin-1]) + '\n'
    fout.write(s)
    
    # print the record_num row
    s = 'reco_num'
    for i in range(n_bin):
        s = s + ',' + str(userItemHist[i])
    s = s + ',' + str(userItemHist_less90p)
    for i in range(len(userItemHist90p)):
        s = s + ',' + str(userItemHist90p[i])
    s = s + ',' + str(userItemHist_less50p) + ','  + str(userItemHist_greater50p) + '\n'
    fout.write(s)
    
    # print the percentage row
    s = 'percentage'
    total = sum(userItemHist)
    for i in range(n_bin):
        p_i = userItemHist[i] / float(total)
        s = s + ',' + str(p_i)
    p_less90p = float(userItemHist_less90p) / total
    s = s + ',' + str(p_less90p)
    for i in range(len(userItemHist90p)):
        p_i = userItemHist90p[i] / float(total)
        s = s + ',' + str(p_i)
    p_less50p = float(userItemHist_less50p) / total
    p_greater50p = float(userItemHist_greater50p) / total
    s = s + ',' + str(p_less50p) + ',' + str(p_greater50p) + '\n'
    fout.write(s)
    
else:
    fout.write('percentage_range,bin_max_item_freq,record_num,percentage\n')
    total = sum(userItemHist)
    for i in range(n_bin):
        p_i = userItemHist[i] / float(total)
        percentage_i_left = 100 / float(n_bin) * i
        percentage_i_right = 100 / float(n_bin) * (i + 1)
        percentage_s = str(percentage_i_left) + '-' + str(percentage_i_right)
        s = percentage_s + ',' + str(bin_max_list[i]) + ',' + str(userItemHist[i]) + ',' + str(p_i) + '\n'
        fout.write(s)
    # print 0-90%
    p_less90p = float(userItemHist_less90p) / total
    s = '0-90,' + str(bin_max_90p) + ',' + str(userItemHist_less90p) + ',' + str(p_less90p) + '\n'
    fout.write(s)
    # print 91-100% 
    for i in range(len(userItemHist90p)):
        p_i = userItemHist90p[i] / float(total)
        percentage_i_left = 90 + i
        percentage_i_right = 91 + i
        percentage_s = str(percentage_i_left) + '-' + str(percentage_i_right)
        #print 'n = %d, p=%f'%(userItemHist90p[i], pi)
        s = percentage_s + ',' + str(bin_max_list_90p[i]) + ',' + str(userItemHist90p[i]) + ',' + str(p_i) + '\n'
        fout.write(s)    
    # write statistics for 50 percentile
    p_less50p = float(userItemHist_less50p) / total
    s = '0-50,' + str(bin_max_50p) + ',' + str(userItemHist_less50p) + ',' + str(p_less50p) + '\n'
    fout.write(s)
    p_greater50p = float(userItemHist_greater50p) / total
    s = '51-100,' + str(bin_max_list[n_bin-1]) + ',' + str(userItemHist_greater50p) + ',' + str(p_greater50p) + '\n'
    fout.write(s)
fout.close()
