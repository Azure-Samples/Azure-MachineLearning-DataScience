#### execute .R scripts in command line for multiple experiments.
# Rscript glm.R "~/datasets/airline_1MM.csv" "~/results/glm/glm_1MM.csv"
# Rscript glm.R "~/datasets/airline_2MM.csv" "~/results/glm/glm_2MM.csv"
# Rscript glm.R "~/datasets/airline_5MM.csv" "~/results/glm/glm_5MM.csv"
# Rscript glm.R "~/datasets/airline_10MM.csv" "~/results/glm/glm_10MM.csv"
# Rscript glm.R "~/datasets/airline_20MM.csv" "~/results/glm/glm_20MM.csv"
# Rscript glm.R "~/datasets/airline_50MM.csv" "~/results/glm/glm_50MM.csv"
# Rscript glm.R "~/datasets/airline_100MM.csv" "~/results/glm/glm_100MM.csv"



#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# Inputs:
# fileName <- "airline_1MM.csv"
fileName <- args[1]


# part 1: reading data
pt1 <- proc.time()
df <- read.csv(fileName, header = TRUE, sep = ",", na.strings = "NA")
pt2 <- proc.time()
print("FINISHED LOADING DATA...")


# part 2: data transformation on CRSDepTime
df$CRSDepTime <- floor(df$CRSDepTime / 100)
pt3 <- proc.time()
print("FINISHED DATA TRANSFORMATION...")


# part 3: split train/test
set.seed(123)
smp_size <- floor(0.75 * nrow(df))
train_ind <- sample(seq_len(nrow(df)), size = smp_size)
train <- df[train_ind, ]
test <- df[-train_ind, ] 
pt4 <- proc.time()
print("FINISHED SPLITTING DATA...")



# part 4: fit model
# glm
model_glm <- glm(formula = IsArrDelayed ~ Month+DayofMonth+DayOfWeek+CRSDepTime+Distance, data = train, family=binomial(link='logit'))
pt5 <- proc.time()
print("FINISHED FITTING MODEL...")



# part 5: predict on test
p <- predict(model_glm, newdata = test, type = "response")
pt6 <- proc.time()
print("FINISHED PREDICTION...")



# part 6: output results
results <- data.frame("number of rows" = fileName,
                      "load data" = (pt2-pt1)[[3]],
                      "tranform feature" = (pt3-pt2)[[3]],
                      "split data" = (pt4-pt3)[[3]],
                      "fit model" = (pt5-pt4)[[3]],
                      "prediction" = (pt6-pt5)[[3]],
                      "total" = (pt6-pt1)[[3]])


# "~/results/glm/glm_1MM.csv"
write.csv(results, args[2], row.names = FALSE)
print("FINISHED WRITTING OUTPUTS...")