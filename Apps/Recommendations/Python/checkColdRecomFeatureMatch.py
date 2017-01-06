# 
# In this script we check the returned scoring items when the seed item is cold
# In terms of checking, we check if there is any features with the same value.
# In this version, only one seed item is supported. 

# list of input files:
# 1. catalog file
# 2. trainining file 
# 3. seed file
# 4. the scoring file using cold item support
# Also some file format parameters are provided.
# Another important parameter: cold_upper_bound
# It specifies the largest number of occurrences in
# training is still considered as C2 cold item. If the 
# occurrence is C2+1, then it is considered as warm.

#========== Parameter for PT dataset =========
f_prefix = 'PT3'
f_catalog = 'catalog.csv'
f_train = 'train-sorted.csv'
f_seed = 'seed_as_train.csv'
f_recom = 'scores-sar-cold_reversed.tsv'
f_output = 'list_of_recom_no_feature_match.csv'

f_catalog_header = True
f_seed_header = False
f_seed_sep = ','
f_recom_sep = '\t'
f_recom_beginning_comment = True

cold_upper_bound = 2
#========== Parameter for PT dataset =========

# update file names based on f_prefix. Users need to change them
# accordingly based on your own file organization.
f_train = f_prefix + '/' + f_train
f_catalog = f_prefix + '/' + f_catalog
f_seed = f_prefix + '/' + f_seed
f_recom = f_prefix + '/data/' + f_recom
f_output = f_prefix + '/data/' + f_output
#=============================================================================
# The rest should be be changed in running for different datasets.

# Read the catalog file
print('Read the catalog file')
fin_catalog = open(f_catalog)
line = fin_catalog.readline()
D_catalog = {}
if f_catalog_header:
    # extract feature name
    fnames = line.strip().split(',')[2:]
    line = fin_catalog.readline()
else:
    # use default feature name
    f_num = len(line.strip().split(',')) - 2
    fnames = ['f_' + str(i) for i in range(f_num)]
while line:
    fs = line.strip().split(',')
    itemId = fs[0]
    if itemId not in D_catalog:
        D_catalog[itemId] = {}
    
    # We need to save all feature values for the current item
    fs_feature = fs[2:]
    fs_feature_mvalue = [v.strip().strip('"').split(';') for v in fs_feature]
    for fi in range(len(fs_feature_mvalue)):
        if len(fs_feature_mvalue[fi])==1 and len(fs_feature_mvalue[fi][0])==0:
            # This is an empty feature value
            pass
        else:
            # We process non-empty feature value only
            fi_value_list = fs_feature_mvalue[fi]
            D_catalog[itemId][fi] = {}
            for fv in fi_value_list:
                D_catalog[itemId][fi][fv] = 1
        
    line = fin_catalog.readline()
fin_catalog.close()

# Read the training file
print('Read the training file')
fin_train = open(f_train)
line = fin_train.readline()
D_item_user = {}
while line:
    fs = line.strip().split(',')
    userId = fs[0]
    itemId = fs[1]
    if itemId not in D_item_user:
        D_item_user[itemId] = {}
    D_item_user[itemId][userId] = 1
    
    line = fin_train.readline()
fin_train.close()

# Read the seed file
print('Read the seed file')
fin_seed = open(f_seed)
D_seed = {}
D_item_type = {}
line = fin_seed.readline()
if f_seed_header:
    line = fin_seed.readline()
while line:
    fs = line.strip().split(f_seed_sep)
    userId = fs[0]
    itemId = fs[1]
    D_seed[userId] = itemId
    
    # Determine the type of the seed item
    if itemId not in D_item_type:
        itemFreq = 0
        if itemId in D_item_user:
            itemFreq = len(D_item_user[itemId])
        if itemId in D_catalog:
            if itemFreq > cold_upper_bound:
                itemType = 'W'
            elif itemFreq > 0:
                itemType = 'C2'
            else:
                itemType = 'C1'
        else:
            # M means item missing in the catalog file
            itemType = 'M'
        D_item_type[itemId] = itemType
    
    line = fin_seed.readline()
fin_seed.close()

# In this function we compute the pairwise similarity of items
# based on their features. 
def compareItemFeatures(D_item1, D_item2):
    # This function return the number of matched feature values
    # for multi-valued feature. If at least one value is matched, 
    # we will consider it as matched
    f1_index = D_item1.keys()
    c_count = 0
    for fi in f1_index:
        if fi in D_item2:
            # if both items have this feature
            # then we will compare their feature values
            for fv in D_item1[fi].keys():
                if fv in D_item2[fi]:
                    c_count += 1
                    break
    return c_count

# Read the recomdation file
print('Read the recommendation file')
# We use D_item_sim to cache item pairwise similarity
D_item_sim = {}
# We use D_item_nomatch to cache all seed items with unmatched items returned
D_item_nomatch = {}
fout = open(f_output, 'w')
fin_recom = open(f_recom)
line = fin_recom.readline()
if f_recom_beginning_comment:
    print('Skip the first few lines of comments')
    while line[0]=='#':
        line = fin_recom.readline()
# Process the valid lines one by one
while line:
    fs = line.strip().split(f_recom_sep)
    userId = fs[0]
    itemId = fs[1]
    
    if userId in D_seed:
        seedItemId = D_seed[userId]
        seedItemType = D_item_type[seedItemId]
        if seedItemType=='C1' or seedItemType=='C2':
            # compare item features
            if itemId <= seedItemId:
                itemA = itemId
                itemB = seedItemId
            else:
                itemA = seedItemId
                itemB = itemId
            if itemA not in D_item_sim:
                D_item_sim[itemA] = {}
            if itemB not in D_item_sim[itemA]:
                D_itemA_ft = D_catalog[itemA]
                D_itemB_ft = D_catalog[itemB]
                D_item_sim[itemA][itemB] = compareItemFeatures(D_itemA_ft, D_itemB_ft)
            # logical check
            simAB = D_item_sim[itemA][itemB]
            if simAB==0:
                # the case we need to investigate
                fout.write('userId,' + userId + '\n')
                fout.write('seedItemId,' + seedItemId + '\n')
                fout.write('recomItemId,' + itemId + '\n')
                
                D_item_nomatch[seedItemId] = D_item_nomatch.get(seedItemId, 0) + 1
    
    line = fin_recom.readline()
fin_recom.close()
fout.close()

# Summarize some statistics in the end
n_item_total = len(D_catalog)
n_seed_nomatch = len(D_item_nomatch)
percent_nomatch = float(n_seed_nomatch) / n_item_total
print('the total number of items in catalog is %d'%n_item_total)
print('the total number of seed items which generate recom items with no feature match is %d'%n_seed_nomatch)
print('the percentage of seed items which generate recom items with no feature match is %f'%percent_nomatch)
