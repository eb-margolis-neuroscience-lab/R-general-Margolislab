# R-general
Reusable R functions and scripts for general data analysis and visualizations
## Functions
### PermtestsEBM.R    
```
permtest_mean(list1, list2, tails, showgraph)
```   
Performs a permutation test comparing the means of the 2 lists of data. It shuffles the data 100000 times without replacement.  
Prints to console a p value and optionally displays the histogram of the results of the shuffles
- list1 <- first list of values  
- list2 <- second list of values  
- tails <- one or two tailed computation  
- showgraph <- 'y' or 'n' to show histogram of shuffle results  

### timecourse_meanerror.R  
Set of functions to process sets of series data saved in separate files into series mean ± confidence band format for visualization. Also use [Plotly](https://plotly.com/r/) to generate some typical graphs. Example dataset provided.  
Functions in this file include:  
```
df <- loadhdf5todf(dirname)
```
Loads set of HDF5 formatted series data (e.g. time series data) taking all files in the specified directory  
- Input is the directory containing the dataset. All data from this directory will be read.
- Each file in the directory should be hdf5 format containing just a single column
- Returns dataframe where each column is a series (i.e., one column per file loaded).  

```
df <- loaddelimitedtodf(dirname)
```
Loads set of simple text (.txt) formatted series data (e.g. time series data) taking all files in the specified directory  
- Input is the directory containing the dataset. All data from this directory will be read.
- Each file in the directory should be hdf5 format containing just a single column
- Returns dataframe where each column is a series (i.e., one column per file loaded).  

```
normdf <- normalizewaves(inputdf, numpts, normtyp)
```
Normalizes the data in the dataframe to the indicated baseline interval. Returns a dataframe, same shape as input.
- inputdf <- df where each column is a data series, such as the output from loadhdf5todf or loaddelimitedtodf.   
- numpts <- how many points at the beginning of the data series to use as baseline   
- normtyp <- (1) is subtract (2) is divide  

```
avgdf <- averagetraces(inputdf)
```
Calculates across rows. Returns a dataframe containing the columns: mean, error, timestamps
- inputdf <- df where each column is a data series, such as the output from loadhdf5todf or loaddelimitedtodf.
- Currently calculates SEM for error.
- *TODO: options to calculate other forms of uncertainty.*  

```
graphobj <- meanerrbartimecoursegraph(inputdf, endtime)
```
Returns a Plotly figure object to display means as circles and error as ± error bars.  Can be subsequently styled with [Plotly](https://plotly.com/r/).  
- inputdf <- formatted as columns: mean, error, timestamps, such as the output from averagetraces
- endtime <- the last datapoint to display in the output graph (i.e., the end of the data range to display)  

```
graphobj <- meanconfbandtimecoursegraph(inputdf, endtime)
```
Returns a Plotly figure object to display means as line and error as ± shaded area.  Can be subsequently styled with [Plotly](https://plotly.com/r/).  
- inputdf <- formatted as columns: mean, error, timestamps, such as the output from averagetraces
- endtime <- the last datapoint to display in the output graph (i.e., the end of the data range to display)  

```
graphobj <- individualwavegraph(inputdf, endtime)
```  
Generates a Plotly figure object displaying a line for each column in the input dataframe. Can be subsequently styled with [Plotly](https://plotly.com/r/).  
- inputdf <- df where each column is a data series, such as the output from loadhdf5todf or loaddelimitedtodf.
- endtime <- the last datapoint to display in the output graph (i.e., the end of the data range to display)




  *Updated by EBM 9/13/2023*
