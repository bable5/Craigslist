library(scrapeR)
library(plyr)
library(reshape2)
library(lubridate)
library(multicore)
library(stringr)

setwd("/home/susan/Dropbox/GraphicsGroup/Craigslist/")
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

data$lat[data$lat==0] <- NA
data$long[data$long==0] <- NA

data <- data[,apply(data, 2, function(i) sum(!is.na(i)))!=0]

# correlation matrix of missingness
cor.melt <- melt(cor(is.na(data)))
qplot(data=cor.melt, x=Var1, y=Var2, geom="tile", fill=value) + 
  scale_fill_gradient2(limits=c(-1.1,1.1))
cor.melt[which(cor.melt$value< -0.5),]