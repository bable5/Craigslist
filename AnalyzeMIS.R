library(scrapeR)
library(plyr)
library(reshape2)

setwd("/home/susan/Dropbox/GraphicsGroup/Craigslist/")
url <- "http://www.craigslist.org/about/sites"

cities <- scrape(url)[[1]]
regions <- getNodeSet(cities, '//*[@id="index"]/div[@class="colmask"]')

getRegionInfo <- function(i){
  region.name = xmlAttrs(xmlChildren(xmlChildren(regions[[i]])$h1)$a)
  state.names = xpathApply(regions[[i]], path=paste('//*[@id="index"]/div[@class="colmask"][', i, ']/div/div/div/div/div[@class="state_delimiter"]', sep=""), xmlValue)
  state.subs = xpathApply(regions[[i]], path=paste('//*[@id="index"]/div[@class="colmask"][', i, ']/div/div/div/div/ul', sep=""), xmlChildren)
  cl.urls = as.character(unlist(xpathApply(regions[[i]], path=paste('//*[@id="index"]/div[@class="colmask"][', i, ']/div/div/div/div/ul/li/a', sep=""), xmlAttrs)))
  cl.names = as.character(unlist(xpathApply(regions[[i]], path=paste('//*[@id="index"]/div[@class="colmask"][', i, ']/div/div/div/div/ul/li', sep=""), xmlValue)))
  df <- do.call("rbind", lapply(1:length(state.names), function(j){
    cl.name = sapply(state.subs[[j]], xmlValue)
    reps = sum(names(cl.name)=="li")
    return(data.frame(state=rep(as.character(state.names[j]), reps), region=rep(as.character(region.name), reps), stringsAsFactors=FALSE))
  } )) 
  df$urls <- cl.urls
  df$names <- cl.names
  df
}

craigslistURLs <- do.call("rbind", lapply(1:length(regions), getRegionInfo))

craigslistURLs <- craigslistURLs[which(craigslistURLs$region%in%c("US", "CA")),]

data <- read.csv("./CL-mis.csv", stringsAsFactors=FALSE)

library(lubridate)
data$timezone <- substr(data$datetime, 21, 23)
data$datetime <- strptime(substr(data$datetime, 1, 19), format="%Y-%m-%d, %I:%M%p")
attr(data$datetime, "tzone") <- data$timezone
temp <- strptime(data$datetime[1:20], format="%Y-%m-%d, %I:%M%p")
force_tz(temp, data$timezone[1:20])
