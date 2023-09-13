# Script to compute a permutation test, no replacement, to compare means
# Created EBM 3/06/2022
# Use: list1 <- first sample list of numbers
#     list2 <- second sample list of numbers
#     tails <- one or two tailed computation
#     showgraph <- 'y' or 'n' to show histogram of shuffle results

permtest_mean <- function(list1, list2, tails, showgraph) {
  len1 <- length(list1)
  len2 <- length(list2)
  alldata <- c(list1, list2)
  meandiff <- mean(list2) - mean(list1)
  results<-vector('list',100000)
  for(i in 1:100000){
    x <- split(sample(alldata), rep(1:2, c(len1, len2))) 
    results[[i]]<-mean(x[[1]]) - mean(x[[2]])  
  }
  df <- data.frame(difs = unlist(results))
  permval <- sum(unlist(results) > meandiff) /100000
  if (tails == 1) {
    print (paste("one tailed p val for perm test:", permval, 1-permval))
  }
  if (tails == 2) {
    onetailvals <- c(permval, 1-permval)
    temptail <- min(onetailvals)
    permvaltwo <- temptail*2
    print (paste("two tailed p val for perm test:", permvaltwo))
  }
  if (showgraph == 'y') {
    library(ggplot2)
    thisplot <- ggplot(df, aes(x=difs)) +
      geom_histogram(color="black", fill="blue", alpha=.4) +
      geom_vline(color="navy",lwd=1,lty=2,xintercept = meandiff) +
      theme_classic()+
      ggtitle("Mean Differences from \n 100,000 Permutations")
    return(thisplot)
  }
}