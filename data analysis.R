library(R.matlab)
library(tidyverse)

# change the working directory to where you've downloaded data
setwd("D:/Orientation Discrimination project/Orient_Disc_Crowding/Data")

# Loading data sets
BinComDataRaw <- readMat('BinComDataset.mat')
CrowdingDatasetRaw <- readMat('CrowdingDataset.mat')



# Creating a list which include data of all subjects
BinComData <- BinComDataRaw$BinComDataset
CrowdingDataset <- CrowdingDatasetRaw$CrowdingDataset
rm(BinComDataRaw,CrowdingDatasetRaw)

subject1_df <- as.data.frame(BinComData[1])
ggplot(subject1_df) + geom_point(mapping = aes(x = X2,
                                               y = X5,
                                               colour = X2))  



