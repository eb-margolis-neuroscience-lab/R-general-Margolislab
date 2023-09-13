# Set of functions to process sets of waves into time course mean type graphics
# Updated EBM 3/2/2023

# loadhdf5todf: function to load time course data taking all files in the specified directory
#     Each file should be hdf5 forman containing just one dataset
#     of a single column
#     Input is the directory
#     return dataframe where each column is a sample

# loaddelimitedtodf: function to load time course data taking all files in the specified directory
#     Each file should be simple text containing just one column
#     Input is the directory
#     return dataframe where each column is a sample

# normalizewaves: function to normalize by column input data where each column is a trace
#     input data, how many points to use as baseline, type of calculation (1) is subtract (2) is divide
#     returns a dataframe, same shape as input

# averagetraces: function to calculate mean and error
#     input is dataframe format from loaddelimitedtodf function
#     return dataframe of columns: mean, error, timestamps

# meanerrbartimecoursegraph: function to generate a Plotly graph, circle markers with error bars
#     input is dataframe format from averagetraces and endtime, the last time point on 
#         the x axis that should be displayed
#     returns a Plotly figure object
    
# meanconfbandtimecoursegraph: function to generate a Plotly graph, line graph with error fill
#     input is dataframe format from averagetraces and endtime, the last time point on 
#         the x axis that should be displayed
#     returns a Plotly figure object

# individualwavegraph: function to generate a Plotly graph showing a line for 
#     each column in the input dataframe
#     can also input the last time point on the x axis that should be displayed
#     returns a Plotly figure object

loadhdf5todf <- function(dirname){
  # Use: dirname <- directory containing the data
  # Assumes all files are hdf5 files
  # containing just one dataset  
  library(rhdf5, warn.conflicts = FALSE, quietly=TRUE)
  file_list <- list.files(path = dirname)
  numfiles = length(file_list)
  
  # find the longest length needed
  longestwavelen = 0
  for (i in 1:numfiles){
    this_location <- paste(dirname, file_list[i], sep = "") 
    load_this_file <- H5Fopen(this_location)
    this_struct <- h5ls(this_location) # get the structure of the hdf5 file
    temp_data <- this_struct["name"]
    load_this <- h5read(file = this_location, name = toString(temp_data)) 
    if (nrow(load_this) > longestwavelen) {
      longestwavelen <- nrow(load_this)
    }
    H5Fclose(load_this_file)
  }
  
  # load data into dataframe
  wavestoaverage <- data.frame(matrix(ncol = 1, nrow = longestwavelen))
  for (i in 1:numfiles){
    this_location <- paste(dirname, file_list[i], sep = "") 
    load_this_file <- H5Fopen(this_location)
    this_struct <- h5ls(this_location) 
    this_dataset <- this_struct["name"]
    load_this <- h5read(file = this_location, name = toString(this_dataset))  
    this_name <- gsub('[.h5]','',file_list[i])
    if (length(load_this) < longestwavelen) {
      length(load_this) <- longestwavelen
    }
    wavestoaverage <- cbind(wavestoaverage, load_this)
    colnames(wavestoaverage)[ncol(wavestoaverage)] <- this_name
    H5Fclose(load_this_file)
  }
  wavestoaverage <- wavestoaverage[,-1] # delete empty first column
  return(wavestoaverage)
}


loaddelimitedtodf <- function(dirname) {
  # Use: dirname <- directory containing the data
  # Assumes all files are simple text delimited
  # containing just one column  
  file_list <- list.files(path = dirname)
  numfiles = length(file_list)
  
  # find the longest length needed
  longestwavelen = 0
  for (i in 1:numfiles) {
    temp_data <- read.delim(paste(dirname,file_list[i], sep = "")) 
    if (nrow(temp_data) > longestwavelen) {
      longestwavelen <- nrow(temp_data)
    }
  }
  # load data into dataframe
  wavestoaverage <- data.frame(matrix(ncol = 1, nrow = longestwavelen))
  for (i in 1:numfiles){
    load_this <- as.numeric(unlist(read.delim(paste(dirname,file_list[i], sep = "")))) 
    this_name <- gsub('[.txt]','',file_list[i])
    if (length(load_this) < longestwavelen) {
      length(load_this) <- longestwavelen
    }
    wavestoaverage <- cbind(wavestoaverage, load_this)
    colnames(wavestoaverage)[ncol(wavestoaverage)] <- this_name
   }
  wavestoaverage <- wavestoaverage[,-1] # delete empty first column
  return(wavestoaverage)
}


normalizewaves <- function(thisdata, numpts, normtype) {
  # Use: thisdata is a dataframe where each column is a trace
  #     numpts <- how many points to use as baseline
  #     normtype <- (1) is subtract (2) is diivide
  # returns a dataframe, same shape as input
  totalwaves <- ncol(thisdata)
  for (i in 1:totalwaves) {
    thiscol <- thisdata[i]
    normtothis <- mean(thiscol[1:numpts,])
    if (normtype == 1) {
      thiscol <- thiscol - normtothis
    }
    else if (normtype == 2) {
      thiscol <- thiscol/normtothis
    }
    thisdata[i] <- thiscol
  }
  return(thisdata)
}


averagetraces <- function(thisdata) {
# Use: thisdata is a dataframe where each column is a trace
#     errtype <- in the future, (1) SEM, (2) 95% conf interval, (3) SD
# returns a dataframe of columns: mean, error, timestamps
  library("matrixStats", warn.conflicts = FALSE, quietly=TRUE)
  this_mean <- rowMeans(thisdata, na.rm=TRUE)
  
  # error across each row
  this_sd <- rowSds(as.matrix(thisdata[,c(-1)]), na.rm=TRUE)
  denom_err <- sqrt(apply(X = !is.na(thisdata), MARGIN = 1, FUN = sum))
  this_sem <- this_sd/denom_err
  
  # add x scaling column
  x <- c(1:nrow(thisdata))/2 # for now, assume x scaling is 0.5
  
  # create return df
  col_names <- c("mean", "error", "timestamps")
  mean_err_df <- data.frame(this_mean, this_sem, x)
  colnames(mean_err_df) <- col_names
  return(mean_err_df)
}


meanerrbartimecoursegraph <- function(thisdata, endtime) {
# Use: thisdata is of the format output from averagetraces, a dataframe
  #     with columns mean, error, timestamps
  #    endtime is the last time point on the x axis that should be displayed
  #    assume graph should start at T=0
  # returns a plotly figure object
  if(missing(endtime))  {
    endtime <- nrow(thisdata)
  }
  library(plotly, warn.conflicts = FALSE, quietly=TRUE)
  library(plyr, warn.conflicts = FALSE, quietly=TRUE)
  fontformat <- list(
    family = "Arial",
    size = 18)
  fig <- plot_ly(thisdata, x = ~timestamps, y = ~mean, 
                 type = "scatter", 
                 mode = 'lines+markers',
                 marker = list(size = 14),
                 error_y = ~list(array = error, color = '#000000')) %>%
        layout(showlegend = FALSE, 
               font = fontformat,
                yaxis = list(showgrid=FALSE,
                             ticks="outside", tickwidth=2, ticklen=10,
                             showline= T, linewidth=2, linecolor='black'),
                xaxis = list(title = ('Time'),
                             showgrid=FALSE,
                             zerolinecolor = '#ffff',
                             range = list(0, endtime),
                             ticks="outside", tickwidth=2, ticklen=10,
                             showline= T, linewidth=2, linecolor='black'))
  return(fig)
}


meanconfbandtimecoursegraph <- function(thisdata, endtime) {
  # Use: thisdata is of the format output from averagetraces, a dataframe
  #     with columns mean, error, timestamps
  #    endtime is the last time point on the x axis that should be displayed
  #    assume graph should start at T=0
  # returns a plotly figure object
  if(missing(endtime))  {
    endtime <- nrow(thisdata)
  }
  library(plotly, warn.conflicts = FALSE, quietly=TRUE)
  library(plyr, warn.conflicts = FALSE, quietly=TRUE)
  high <- thisdata$mean+thisdata$error
  low <- thisdata$mean-thisdata$error
  thisdata <- cbind(thisdata, high, low)
  fontformat <- list(
    family = "Arial",
    size = 18)
  fig <- plot_ly(thisdata, x = ~timestamps, y = ~mean, 
                 type = "scatter", 
                 mode = 'lines',
                 line = list(color = 'rgba(67,67,67,1)', width = 4)) %>% 
    add_trace(y = ~high,
              line = list(color = 'rgba(67,67,67,1)', width = 0)) %>%
    add_trace(y = ~low,
               line = list(color = 'rgba(67,67,67,1)', width = 0),
                fill = 'tonexty' ,
                fillcolor='rgba(0,100,80,0.2)') %>%
    layout(showlegend = FALSE, 
           font=fontformat,
           yaxis = list(showgrid=FALSE,
                        ticks="outside", tickwidth=2, ticklen=10,
                        showline= T, linewidth=2, linecolor='black'),
           xaxis = list(title = ('Time'),
                        showgrid=FALSE,
                        zerolinecolor = '#ffff',
                        range = list(0, endtime),
                        ticks="outside", tickwidth=2, ticklen=10,
                        showline= T, linewidth=2, linecolor='black'))
  return(fig)
}


individualwavegraph <- function(thisdata, endtime) {
  # Use: thisdata is of the format output from loaddelimitedtodf, a dataframe
  #     with each column is a data wave
  #     endtime is the last time point on the x axis that should be displayed
  #     assume graph should start at T=0
  # returns a plotly figure object
  if(missing(endtime))  {
    endtime <- nrow(thisdata)
  }
  library(plotly, warn.conflicts = FALSE, quietly=TRUE)
  fontformat <- list(
    family = "Arial",
    size = 18)
  totalwaves <- ncol(thisdata)
  x <- c(1:nrow(thisdata))
  firstdata <- thisdata[,1]
  data <- data.frame(x, firstdata)
  fig <- plot_ly(data, x = ~x, y = ~firstdata, type = 'scatter', 
                 mode = 'lines', name = colnames(thisdata[1]))
  for (i in 2:totalwaves) {
    fig <- fig %>% add_trace(y = thisdata[,i], mode = 'lines', 
                             name = colnames(thisdata[i])) 
  } 
  fig <- fig %>% layout(showlegend = FALSE, 
         font = fontformat,
         yaxis = list(showgrid=FALSE,
                      ticks="outside", tickwidth=2, ticklen=10,
                      showline= T, linewidth=2, linecolor='black'),
         xaxis = list(title = ('Index'),
                      showgrid=FALSE,
                      zerolinecolor = '#ffff',
                      range = list(0, endtime),
                      ticks="outside", tickwidth=2, ticklen=10,
                      showline= T, linewidth=2, linecolor='black'))
  return(fig)
}


# ------------------------------------------------------------------------------
# for testing (3/2/2023)
# delimited data dirname = "/Users/elyssamargolis/Desktop/Projects/KOR stress/manuscript files/fig_data/U69excit_stress_timecourse/"
# hdf5 data dirname = "/Users/elyssamargolis/Desktop/Projects/KOR stress/manuscript files/fig_data/U69inhib_stress_timecourse/"