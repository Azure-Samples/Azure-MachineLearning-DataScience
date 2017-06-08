# Simple regression on mtcars dataset

rsqr <- c()
system.time(
for (k in 1:nrow(mtcars)) {
    rsqr[k] <- summary(lm(mpg ~ . , data=mtcars[-k,]))$r.squared
})
cat('Leave one out summary', summary(rsqr),'\n')
