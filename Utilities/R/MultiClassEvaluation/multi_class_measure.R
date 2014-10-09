# In this script, we compute performance measures for multi-class classification, including:
# 1. Micro-averaged F1 score
# 2. Macro-avereaged F1 score
# 3. MAUC, AUC extension for multi-class classification.

# Map 1-based optional input ports to variables
# Make sure dataset1 is the prediction, 
# dataset2 only contains the column of the ground truth of the target.
dataset1 <- maml.mapInputPort(1) # class: data.frame
dataset2 <- maml.mapInputPort(2) # class: data.frame

#======================= Function Part ========================================================
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

# This part is copied from classification_measure.R
# It contains many functions to compute the performance metrics for both 
# binary and multi-class classification. 
#=============== Functions for both multi-class and binary-class classification ===============

# This function computes the accuracy,
# Input: 
# a k-by-k confusion matrix, where
# k is the number of classes
# We use Conf to denote the input should be a k-by-k confusion matrix
# Output:
# a scalar.
accuracyConf<-function(M) {
  a = sum(diag(M)) / sum(M)  
  return(a)
}


# This function computes the accuracy,
# Input: 
# y_true: the true label, a vector with length n
# y_predict: the predicted label, a vector with length n
# We use Y to denote the input should be the prediction and the groundtruth
# Output:
# a scalar.
accuracyY<-function(y_true, y_predict) {
  if(length(y_true)!=length(y_predict)) {
    return(-1)
  }
  a = sum(y_true==y_predict) / length(y_true)
  return(a)
}


#=============== Functions for binary-class classification ===============

# This function computes the confusion matrix for binary-class classification
# Input:
# y_true: the true label, a vector with length n
# y_predict: the predicted label, a vector with length n
# **** NOTES *****
# y_true and y_predict can only contain either 1 or 0. Other entries will not be accepted and may 
# cause an error.
# *****************
# output:
# It returns a 2-by-2 confusion matrix and the list of labels
# For the confusion matrix M, M[i,j] is the number of 
# samples in class i is predicted as class j
# If an error happends, it returns -1
confusion_binary<-function(y_true, y_predict) {
  n = length(y_true)
  if (sum(y_true==0 | y_true==1)!= n || sum(y_predict==0 | y_predict==1)!=n) {
    return(-1)
  }
  
  M = matrix(0, 2, 2)
  M[1,1] = sum(y_true*y_predict)
  M[1,2] = sum(y_true*(y_predict==0))
  M[2,1] = sum((y_true==0)*y_predict)
  M[2,2] = sum((y_true==0)*(y_predict==0))
  R = {}
  R$confusionMatrix = M
  R$labelList = c(1,0)
  return(R)
}  


# This function computes the recall for binary-classification
# Input: 
# the input is a 2-by-2 confusion matrix
# M[1,1]: the sample # which are true class 1 and also predicted as class 1
# M[1,2]: the sample # which are true class 1 but predicted as class 2
# We treat class 1 as positive class and compute the corresponding recall. 
# Output:
# a scalar 
recall_binary<-function(M) {
  if (sum(M[1,])!=0) {
    r = M[1,1] / sum(M[1,])  
  }else {
    r = 0
  }
  
  return(r)
}

# This function computes the precision for binary classification
# Input: 
# the input is a 2-by-2 confusion matrix for binary classification
# The 1st class is considered as positive class and the 2nd class is considered as negative class.
# Output:
# a scalar
precision_binary<-function(M) {
  if (sum(M[,1])!=0) {
    p = M[1,1] / sum(M[,1])  
  }else {
    p = 0
  }
  
  return(p)
}

# This function computes the F1 for binary classification, 
# Input:
# The input is a 2-by-2 confusion matrix for binary classification
# The 1st class is considered as positive class and the 2nd class is considered as negative class.
# Output:
# a scalar
F1_binary<-function(M) {
  p = precision_binary(M)
  r = recall_binary(M)
  if (p==0&&r==0) {
    f = 0
  }else {
    f = 2 * p * r / (p+r)
  }
  
  return(f)
}

#=============== Functions for multi-class classification ===============


# This function computes the confusion matrix for multi-class classification
# Input:
# y_true: the true label, a vector with length n
# y_predict: the predicted label, a vector with length n
# output:
# It returns a k-by-k confusion matrix and the list of labels
# For the confusion matrix M, M[i,j] is the number of 
# samples in class i is predicted as class j
# If an error happends, it returns -1
confusion_multi<-function(y_true, y_predict, labelList=F) {
  if (length(y_true)!=length(y_predict)) {
    M = -1
    return(M)
  }
  
  if (any(labelList==F)) {
    k_list = sort(unique(y_true))
  }else{
    k_list = labelList
  }  
  k = length(k_list)
  # map all classes to 1 to k. If in y_predict there is more labels, map all of them to 0
  y_true_new = rep(0, length(y_true))
  y_predict_new = rep(0, length(y_predict))
  for(i in 1:k) {
    label = k_list[i]
    y_true_new[which(y_true==label)] = i
    y_predict_new[which(y_predict==label)] = i
  }
  
  M = matrix(0, k, k)
  for (i in 1:length(y_true)) {
    y_true_i = y_true_new[i]
    y_predict_i = y_predict_new[i]
    if (y_predict_i!=0) {
      M[y_true_i, y_predict_i] = M[y_true_i, y_predict_i] + 1
    }
    
  }
  R = {}
  R$confusionMatrix = M
  R$labelList = k_list
  
  return(R)
}
# This function computes recall for multi-class learning problem
# Input:
# The input is a k-by-k confusion matrix
# Output:
# The output is a vector of length k, and the i-th entry is the recall for the i-th class
recall_multi<-function(M) {
  k = dim(M)[1]
  rk = rep(0, k)
  n_total = sum(M)
  for (i in 1:k) {
    M2 = matrix(0, 2, 2)
    M2[1,1] = M[i,i]
    M2[1,2] = sum(M[i,]) - M[i,i]
    M2[2,1] = sum(M[,i]) - M[i,i]
    M2[2,2] = n_total - M2[1,1] - M2[1,2] - M[2,1]
    
    r2 = recall_binary(M2)
    rk[i] = r2
  }
  return(rk)
}

# This function computes precision for multi-class learning problem
# Input:
# The input is a k-by-k confusion matrix
# Output:
# The output is a vector of length k, and the i-th entry is the precision for the i-th class
precision_multi<-function(M) {
  k = dim(M)[1]
  pk = rep(0, k)
  n_total = sum(M)
  for (i in 1:k) {
    M2 = matrix(0, 2, 2)
    M2[1,1] = M[i,i]
    M2[1,2] = sum(M[i,]) - M[i,i]
    M2[2,1] = sum(M[,i]) - M[i,i]
    M2[2,2] = n_total - M2[1,1] - M2[1,2] - M[2,1]
    
    p2 = precision_binary(M2)
    pk[i] = p2
  }
  return(pk)
}

# This function computes F1 for multi-class learning problem
# Input:
# The input is a k-by-k confusion matrix
# Output:
# The output is a vector of length k, and the i-th entry is the F1 for the i-th class
F1_multi<-function(M) {
  k = dim(M)[1]
  fk = rep(0, k)
  n_total = sum(M)
  for (i in 1:k) {
    M2 = matrix(0, 2, 2)
    M2[1,1] = M[i,i]
    M2[1,2] = sum(M[i,]) - M[i,i]
    M2[2,1] = sum(M[,i]) - M[i,i]
    M2[2,2] = n_total - M2[1,1] - M2[1,2] - M[2,1]
    
    f1 = F1_binary(M2)
    fk[i] = f1
  }
  return(fk)
}

# This function computes macro-averaged F1 for multi-class learning problem
# Input:
# The input is a k-by-k confusion matrix
# Output:
# The output is the macro-averaged F1 (a scalar)
macroF1 <-function(M) {
  fk = F1_multi(M)
  return(mean(fk)) 
}


# This function computes micro-averaged F1 for multi-class learning problem
# Input:
# The input is a k-by-k confusion matrix
# Output:
# The output is the micro-averaged F1 (a scalar)
microF1 <-function(M) {
  k = dim(M)[1]
  M2_sum = matrix(0, 2, 2)
  
  n_total = sum(M)
  for (i in 1:k) {
    M2 = matrix(0, 2, 2)
    M2[1,1] = M[i,i]
    M2[1,2] = sum(M[i,]) - M[i,i]
    M2[2,1] = sum(M[,i]) - M[i,i]
    M2[2,2] = n_total - M2[1,1] - M2[1,2] - M[2,1]
    
    M2_sum = M2_sum + M2
  }
  F1 = F1_binary(M2_sum)
  return(F1)
}


#=====================Functions for AUC and MAUC ============================
# This function computes AUC for binary-classification
# Input: 
# g: vector with length n, it is the ground truth. Note that g[i] is either 0 or 1.
# p: vector iwth length n, it is the prediction. p[i] is our prediction for the i-th sample.
# Output:
# it returns the Area Under the ROC Curve (a scalar)
# If an error happens, it returns -1
AUC<-function(g, p) {
  if (length(g)!=length(p)) {
    return(-1)
  }
  
  n = length(g)
  s_total = 0
  for (i in 1:(n-1)) {
    for (j in (i+1):n) {
      if (g[i]!=g[j]) {
        if (g[i]==0) {
          if (p[i]<p[j]) {
            s_total <- s_total + 1
          }else if (p[i]==p[j]) {
            s_total <- s_total + 0.5
          }
        }else {
          if (p[i]>p[j]) {
            s_total <- s_total + 1
          }else if (p[i]==p[j]) {
            s_total <- s_total + 0.5
          }
        }
      }
    }
  }
  n_pos = sum(g==1)
  n_neg = sum(g==0)
  s = s_total / n_pos / n_neg
  return(s)  
}

# This function computes MAUC proposed in this paper:
# David J. Hand and Robert J. Till (2001). A Simple Generalisation of the Area 
# Under the ROC Curve for Multiple Class Classification Problems. Machine 
# Learning 45(2), p. 171--186
# Input:
# labelList: the list of labels
# g: vector with length n, it is the ground truth, and g[i] must be in labelList
# P: n-by-k matrix, where P(i,j) is the probability (or 
# some quantity similar) the i-th sample xi is assign to class Cj, where
# Cj is the the class corresponding labelList[j]. k is the number of labels,
# and k=length(labelList)
# Output:
# It returns the MAUC (a scalar)
MAUC<-function(g, P, labelList = NULL) {
  if (is.null(labelList)) {
    labelList = sort(unique(g))
  }  
  k = length(labelList)
  ss_total = 0
  for(p in 1:(k-1)) {
    for(q in (p+1):k) {
      sp = P[,p]
      sp = sp[g==labelList[p] | g==labelList[q]]
      gp = g[g==labelList[p] | g==labelList[q]]  
      gp_new = rep(0, length(gp))
      gp_new[gp==labelList[p]] = 1
      auc_pq = AUC(gp_new, sp)
      
      sq = P[,q]
      sq = sq[g==labelList[p] | g==labelList[q]]
      gq = g[g==labelList[p] | g==labelList[q]]  
      gq_new = rep(0, length(gq))
      gq_new[gq==labelList[q]] = 1
      auc_qp = AUC(gq_new, sq)
      
      
      ss_total = ss_total + auc_pq + auc_qp
    }
  }
  mauc = ss_total / k / (k-1)
  return(mauc)
}

#=============================================================================================
# This function extracts the class label
# The returned label is a string
extractClass<-function(str) {
  prefix_length <- nchar('Scored.Probabilities.for.Class.')
  label <- substr(str, prefix_length+1, nchar(str))
  if (substr(label, 1, 1) == '"') {
    label <- substr(label, 2, nchar(label))
  }
  if (substr(label, nchar(label), nchar(label)) == '"') {
    label <- substr(label, 1, nchar(label)-1)
  }
  return(label)
}


#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#======================= Function Part ========================================================
# setwd("C:/Users/liasun/Documents/comparison/ML_Studio")
# dataset1 <- read.csv('Data/Glass_MLogistic_Predictions.csv', header = T)
# dataset2 <- read.csv('Data/Glass_ytrue.csv', header = T)

predictions_raw <- dataset1
y_true <- dataset2[[1]]



# Extract the class number, prediction probabilities, and final predictions.
n_samples <- dim(predictions_raw)[1]
n_classes <- length(unique(y_true))
n_features <- dim(predictions_raw)[2] - n_classes - 2

y_pred <- predictions_raw[[dim(predictions_raw)[2]]]

# Compute the confusion matrix compute different metrics except MAUC
ConfM <- confusion_multi(y_true, y_pred)
M <- ConfM$confusionMatrix
macroF1_score <- macroF1(M)
microF1_score <- microF1(M)
recall_vector <- recall_multi(M)
precision_vector <- precision_multi(M)
F1_vector <- F1_multi(M)
acc <- accuracyConf(M)

# Compute MAUC 
# Extrac the probability matrix 
p_matrix <- predictions_raw[, (n_features+2):(dim(predictions_raw)[2]-1)]
p_name <- names(p_matrix)
p_class_list <- rep('', n_classes)
for (i in 1:n_classes) {
  p_class_list[i] <- extractClass(p_name[i])
}
if (is.numeric(y_true)) {
  p_class_list <- as.numeric(p_class_list)
}
# map ground truth if neccessary
if (is.numeric(y_true)) {
  y_true_format <- rep(0, n_samples)
}else {
  y_true_format <- rep('', n_samples)
}
for(i in 1:length(p_class_list)) {
  label <- p_class_list[i]
  y_true_format[y_true==label] = label
}
mauc <- MAUC(y_true_format, p_matrix, labelList = p_class_list)



dataset.out <- data.frame()
dataset.out[1, 'Accuracy'] <- acc
dataset.out[1, 'MacroF1'] <- macroF1_score
dataset.out[1, 'MicroF1'] <- microF1_score
dataset.out[1, 'MAUC'] <- mauc

# Select data.frame to be sent to the output Dataset port
maml.mapOutputPort("dataset.out")
