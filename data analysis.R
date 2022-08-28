library(R.matlab)
library(tidyverse)

# change the working directory to where you've downloaded data
setwd("D:/Orientation Discrimination project/Orient_Disc_Crowding/Data")

data <- read.mat('1001_training.mat')

# convert data from a matrix into a dat frame
data <- as.data.frame(data$Response)

crowdTrials <- dplyr::filter(data1,V5==0)
catchTrials <- dplyr::filter(data1,V5==1)
performance <- crowdTrials %>% group_by(V2) %>% summarise(avg = mean(V3))
