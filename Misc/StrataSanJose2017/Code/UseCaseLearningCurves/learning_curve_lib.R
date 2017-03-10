# Use random number seed to select the rows to be used for training or testing.
# Collect error stats for training set from the model when possible.

# execObjects = c("data_table", "SALT")
run_training_fraction <- function(model_class, training_fraction, 
                                  with_formula, test_set_kfold_id, KFOLDS=3, ...){
  learner <- get(model_class)
  
  NUM_BUCKETS <- 1000 # for approximate AUC
  
  row_tagger <- function(data_list, start_row, num_rows, 
                         chunk_num, prob, kfolds, kfold_id, salt){
    rowNums <- seq(from=start_row, length.out=num_rows)
    set.seed(chunk_num + salt)
    kfold <- sample(1:kfolds, size=num_rows, replace=TRUE)
    in_test_set <- kfold == kfold_id
    num_training_candidates <- sum(!in_test_set)
    keepers <- sample(rowNums[!in_test_set], prob * num_training_candidates)
    data_list$in_training_set <- rowNums %in% keepers
    data_list$in_test_set <- in_test_set
    data_list
  }
  
  row_selection_transform <- function(data_list){
    row_tagger(data_list, .rxStartRow, .rxNumRows, .rxChunkNum, 
               prob, kfolds, kfold_id, salt)
  }
  
  # Calculate RMSE (root mean squared error) for predictions made with a given model on a dataset.
  # Only rows in the test set are counted.
  RMSE_transform <- function(data_list){
    if (.rxChunkNum == 1){
      .rxSet("SSE", 0)
      .rxSet("rowCount", 0)
    }
    SSE <- .rxGet("SSE")
    rowCount <- .rxGet("rowCount")
    
    data_list <- row_tagger(data_list, .rxStartRow, .rxNumRows, .rxChunkNum, 
                            prob, kfolds, kfold_id, salt)
    
    # rxPredict returns a dataframe if you give it one. # data_list$in_test_set
    if (class(model)[1] == "SDCAR"){
      test_chunk <- as.data.frame(data_list)[data_list[[SET_SELECTOR]],]
      outcome_var <- model$params$formulaVars[1]
      residual <- rxPredict(model, test_chunk)[[1]] - test_chunk[[outcome_var]]
    } else { 
      residual <- rxPredict(model, as.data.frame(data_list)[data_list[[SET_SELECTOR]],], 
                             computeResiduals=TRUE, residVarNames="residual")$residual
    }
    
    SSE <- SSE + sum(residual^2, na.rm=TRUE)
    rowCount <- rowCount + sum(!is.na(residual))
    .rxSet("SSE", SSE)
    .rxSet("rowCount", rowCount)
    return(data_list)
  }
  
  AUC_transform <- function(data_list){
    # NUM_BUCKETS <- 100;
    if (.rxChunkNum == 1){
      # assume the first chunk gives a reasonably representative sample of score distribution
      # chunk1_scores <- rxPredict(model, as.data.frame(data_list))[[1]]
      # quantile_breaks <- unique(quantile(chunk1_scores, probs=0:NUM_BUCKETS/NUM_BUCKETS)))
      # scores must be in range of probabilities (between 0 and 1)
      .rxSet("BREAKS", (0:NUM_BUCKETS)/NUM_BUCKETS) # 
      .rxSet("TP", numeric(NUM_BUCKETS))
      .rxSet("FP", numeric(NUM_BUCKETS))
    }
    TPR <- .rxGet("TP")
    FPR <- .rxGet("FP")
    BREAKS <- .rxGet("BREAKS")
    
    data_list <- row_tagger(data_list, .rxStartRow, .rxNumRows, .rxChunkNum, 
                            prob, kfolds, kfold_id, salt)
    
    data_set <- as.data.frame(data_list)[data_list[[SET_SELECTOR]],]
    labels <- data_set[[model$param$formulaVars$original$depVars]]
    scores <- rxPredict(model, data_set)[[1]] # rxPredict returns a dataframe if you give it one.
    bucket <- cut(scores, breaks=BREAKS, include.lowest=TRUE)
    
    # data.frame(labels, scores, bucket)
    TP <- rev(as.vector(xtabs(labels ~ bucket))) # positive cases in each bucket, top scores first
    N <- rev(as.vector(xtabs( ~ bucket))) # total cases in each bucket
    FP <- N - TP
    
    .rxSet("TP", TP)
    .rxSet("FP", FP)
    return(data_list)
  }
  
  simple_auc <- function(TPR, FPR){
    dFPR <- c(0, diff(FPR))
    sum(TPR * dFPR) - sum(diff(TPR) * diff(FPR))/2
  }
  
  calculate_RMSE <- function(with_model, xdfdata, set_selector){
    xformObjs <- rxDataStep(inData=xdfdata, 
                            transformFunc=RMSE_transform, 
                            transformVars=c(rxGetVarNames(xdfdata) ), 
                            transformObjects=list(SSE=0, rowCount=0, SET_SELECTOR=set_selector,
                                                  model=with_model, row_tagger=row_tagger,
                                                  prob=training_fraction, kfolds=KFOLDS, 
                                                  kfold_id=test_set_kfold_id,
                                                  salt=SALT), 
                            returnTransformObjects=TRUE)
    with(xformObjs, sqrt(SSE/rowCount))
  }
  
  calculate_AUC <- function(with_model, xdfdata, set_selector){
    # NUM_BUCKETS <- 100; kfolds=3
    xformObjs <- rxDataStep(inData=xdfdata, 
                            transformFunc=AUC_transform, 
                            transformVars=c( rxGetVarNames(xdfdata) ), 
                            transformObjects=list(TP=numeric(NUM_BUCKETS), FP=numeric(NUM_BUCKETS),
                                                  SET_SELECTOR=set_selector,
                                                  model=with_model, row_tagger=row_tagger,
                                                  prob=training_fraction, kfolds=KFOLDS, 
                                                  kfold_id=test_set_kfold_id, 
                                                  salt=SALT), 
                            returnTransformObjects=TRUE)
    with(xformObjs, {
      TPR <- cumsum(TP)/sum(TP)
      FPR <- cumsum(FP)/sum(FP)
      simple_auc(TPR, FPR)
    })
  }
  
  get_training_error <- function(fit) {
    switch( class(fit)[[1]],
            rxLinMod = with(summary(fit)[[1]], sqrt(residual.squares/nValidObs)),
            rxBTrees =,
            rxDForest = if(!is.null(fit$type) && "anova" == fit$type){
                  calculate_RMSE(fit, data_table, "in_training_set")
                } else {
                  calculate_AUC(fit, data_table, "in_training_set")
                },
            rxDTree = if ("anova" == fit$method){
                  calculate_RMSE(fit, data_table, "in_training_set")
                } else { # "class"
                  calculate_AUC(fit, data_table, "in_training_set")
                },
            rxLogit = calculate_AUC(fit, data_table, "in_training_set"),
            SDCA = calculate_AUC(fit, data_table, "in_training_set"), 
              #rxFastLinear, class = SDCA (BinaryClassifierTrainer)
            SDCAR = calculate_RMSE(fit, data_table, "in_training_set")
              # rxFastLinear, class = SDCAR (RegressorTrainer)
    )
  }
  
  get_test_error <- function(fit) {
    switch( class(fit)[[1]],
            rxLinMod = calculate_RMSE(fit, data_table, "in_test_set"),
            rxBTrees =,
            rxDForest = if(!is.null(fit$type) && "anova" == fit$type){
                calculate_RMSE(fit, data_table, "in_test_set")
              } else { # fit$type == "class"
                calculate_AUC(fit, data_table, "in_test_set")
              },
            rxDTree = if ("anova" == fit$method){
                calculate_RMSE(fit, data_table, "in_test_set")
              } else { # "class"
                calculate_AUC(fit, data_table, "in_test_set")
              },
            rxLogit = calculate_AUC(fit, data_table, "in_test_set"),
            SDCA = calculate_AUC(fit, data_table, "in_test_set"), 
            #rxFastLinear, class = SDCA (BinaryClassifierTrainer)
            SDCAR = calculate_RMSE(fit, data_table, "in_test_set")
            # rxFastLinear, class = SDCAR (RegressorTrainer)
    )
  }
  
  get_tss <- function(fit){
    switch( class(fit)[[1]],
            rxLinMod = ,
            rxLogit = fit$nValidObs,
            rxDTree = fit$valid.obs,
            rxBTrees =,
            rxDForest =,
            SDCA =,
            SDCAR = training_fraction * (1 - 1/KFOLDS) * rxGetInfo(data_table)$numRows
    )
  }
  
  train_time <- system.time(
    fit <- learner(as.formula(with_formula), data_table,
                    rowSelection=(in_training_set == TRUE),
                    transformFunc=row_selection_transform,
                    transformObjects=list(row_tagger=row_tagger, prob=training_fraction, 
                                          kfold_id=test_set_kfold_id, kfolds=KFOLDS,
                                          salt=SALT),
                   ...)
  )[['elapsed']]
  
  e1_time <- system.time(
    training_error <- get_training_error(fit)
  )[['elapsed']]
  
  e2_time <- system.time(
    test_error <- get_test_error(fit)
  )[['elapsed']]
  
  data.frame(tss=get_tss(fit), model_class=model_class, training=training_error, test=test_error,
             train_time=train_time, train_error_time=e1_time, test_error_time=e2_time, 
             formula=with_formula, kfold=test_set_kfold_id, ...)

}


create_formula <- function(outcome, varnames, interaction_pow=1){
  vars <- paste(setdiff(varnames, outcome), collapse=" + ")
  if (interaction_pow > 1) vars <- sprintf("(%s)^%d", vars, interaction_pow)
  sprintf("%s ~ %s", outcome, vars)
}

#' get_training_fractions
#' Create a vector of fractions of available training data to be used at the evaluation 
#' points of a learning curve.
#' @param min_tss; target minimum training set size.
#' @param max_tss: approximate maximum training set size. This is used to calculate the 
#' fraction used for the smallest point.
#' @param num_tss: number of training set sizes.
get_training_set_fractions <- function(min_tss, max_tss, num_tss)
  exp(seq(log(min_tss/max_tss), log(1), length=num_tss))
