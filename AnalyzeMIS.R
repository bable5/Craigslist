library(scrapeR)
library(plyr)
library(reshape2)
library(lubridate)
library(multicore)
library(stringr)
library(ggplot2)

# setwd("/home/susan/Dropbox/GraphicsGroup/Craigslist/")
source("./timezones.R")
timezones.conv <- unique(timezones[,c("Abbr.", "trunc")])

url <- "http://www.craigslist.org/about/sites"

data <- read.csv("./CL-mis.csv", stringsAsFactors=FALSE)
data <- apply(data, 2, str_trim)
data <- apply(data, 2, function(i) {
                i[str_length(i)==0] <- NA
                return(i)})
data <- as.data.frame(data, stringsAsFactors=FALSE)

data$timezone <- substr(data$datetime, 21, 23)
data$timezone[is.na(data$timezone)] <- "UTC"
timezoneidx <- unlist(mclapply(data$timezone, function(i) which(timezones.conv$trunc==i)[1]))
tz.tab <- timezones.conv[unique(timezoneidx),]
data$timezone <- timezones.conv$Abbr.[timezoneidx]

data$datetime2 <- unlist(mclapply(1:nrow(data), function(i) strftime(substr(data$datetime[i], 1, 19), format="%Y-%m-%d, %I:%M%p", tz=data$timezone[i], usetz=TRUE)))

# clean latitude/longitude
data$lat <- as.numeric(data$lat)
data$long <- as.numeric(data$long)
data$data.latitude <- as.numeric(data$data.latitude)
data$data.longitude <- as.numeric(data$data.longitude)
data$lat[data$lat==0] <- NA
data$long[data$long==0] <- NA
data$data.latitude[data$data.latitude==0] <- NA
data$data.longitude[data$data.longitude==0] <- NA

data$lat <- rowSums(cbind(data$lat, data$data.latitude), na.rm=TRUE)
data$lat[data$lat==0] <- NA
data$long <- rowSums(cbind(data$long, data$data.longitude), na.rm=TRUE)
data$long[data$long==0] <- NA
data <- data[,-c("data.longitude", "data.latitude")]


# get rid of all NA columns
data <- data[,apply(data, 2, function(i) sum(!is.na(i)))!=0]

# correlation matrix of missingness
cor.melt <- melt(cor(is.na(data)))
qplot(data=cor.melt, x=Var1, y=Var2, geom="tile", fill=value) + 
  scale_fill_gradient2(limits=c(-1.1,1.1))
cor.melt[which(cor.melt$value< -0.5),]

# parse postTitle
data$postCategory <- sapply(data$postTitle, function(i) 
                            strsplit(i, ' - ')[[1]][2])

data$age <- as.numeric(sapply(data$postTitle, function(i) 
            strsplit(strsplit(i, ' - ')[[1]][3], " (", fixed=TRUE)[[1]][1]))
data$location <- sapply(data$postTitle, function(i) gsub(")", "", 
                             strsplit(i, ' (', fixed=TRUE)[[1]][2],
                             fixed=TRUE))

