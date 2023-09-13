# R-general
Reusable R functions and scripts for general data analysis and visualizations
## Functions
### PermtestsEBM.R    
*permtest_mean(list1, list2, tails, showgraph)*   
Performs a permutation test comparing the means of the 2 lists of data. It shuffles the data 100000 times without replacement.  
Returns a p value and optionally displays the histogram of the results of the shuffles
- list1 <- first list of values  
- list2 <- second list of values  
- tails <- one or two tailed computation  
- showgraph <- 'y' or 'n' to show histogram of shuffle results  
