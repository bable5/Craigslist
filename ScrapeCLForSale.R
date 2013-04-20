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


parsePost <- function(i){
  linkinfo <- try({
    kids <- xmlChildren(i)
    pagelinkattrs <- data.frame(t(xmlAttrs(i)), stringsAsFactors=FALSE)
    pagelink <- as.character(xmlAttrs(getNodeSet(i, "*/a")[[1]]))
    pagelinkclass <- t(data.frame(t(sapply(which(names(kids)=="span"), function(j) unlist(c(xmlAttrs(kids[[j]]), xmlValue(kids[[j]])))[1:2])), row.names=1))
    data.frame(pagelinkattrs, link=pagelink, pagelinkclass, stringsAsFactors=FALSE)
  })
  postinfodata <- try({
    postinfo <- scrape(pagelink)
    emailreply <- xmlValue(sapply(postinfo, getNodeSet, '//*[@id="pagecontainer"]/section/section[@class="dateReplyBar"]/div[@class="returnemail"]')[[1]])
#     emailreply <- if(length(emails)>0) as.character(lapply(emails, xmlValue, FALSE, FALSE))
    dateposted <- as.character(lapply(sapply(postinfo, getNodeSet, 
                  '//*[@id="pagecontainer"]/section/section[@class="dateReplyBar"]/p[@class="postinginfo"]/date'), 
                  xmlValue, FALSE, FALSE))
    
    imgs <- sapply(postinfo, getNodeSet, '//*[@id="pagecontainer"]/section/section[@class="userbody"]/figure/div[@id="thumbs"]/a')
    if(length(unlist(imgs))>0)   imglink <- data.frame(do.call("rbind", lapply(imgs, xmlAttrs, FALSE, FALSE)), stringsAsFactors=FALSE) else imglink <- data.frame(NA, NA)  
    names(imglink) <- c("ImageLink", "ImageTitle")
    text <- as.character(lapply(sapply(postinfo, getNodeSet, '//*/section[@id="postingbody"]'), xmlValue, FALSE, FALSE))
    title <- as.character(lapply(sapply(postinfo, getNodeSet, '//*/h2[@class="postingtitle"]'), xmlValue, FALSE, FALSE))
    id <- strsplit(as.character(lapply(sapply(postinfo, getNodeSet, '//*/div[@class="postinginfos"]/p[@class="postinginfo"][1]'), xmlValue, FALSE, FALSE)), ": ")[[1]][2]
    data.frame(email=emailreply, datetime=dateposted, imglink, postText=text, postTitle=title, postID=id, stringsAsFactors=FALSE)
  })
  if(is.character(postinfodata) & is.character(linkinfo)) return(data.frame()) else
    if(is.character(postinfodata) & !is.character(linkinfo)) return(linkinfo) else
      if(!is.character(postinfodata) & is.character(linkinfo)) return(postinfodata) else
        return(cbind(postinfodata, linkinfo))
  return(cbind(postinfodata, linkinfo))
}
getCityPosts <- function(city, subcl="sss"){
  url <- paste(paste(city, "/", subcl, sep=""), c("/", "/index100.html", "/index200.html"), sep="")
  site <- try(scrape(url))
  if(is.character(site)) return(data.frame(city=city, subcl=subcl))
  posts <- unlist(lapply(site, function(i) getNodeSet(i, "//*/p")[1:100]))
  postdata <- suppressWarnings(rbind.fill(lapply(posts, parsePost), stringsAsFactors=FALSE))
  cbind(city=city, subcl = subcl, postdata)
}

# postcity <- getCityPosts(craigslistURLs[100,3], subcl="sss")


AllCraigslistURLs <- craigslistURLs
craigslistURLs <- craigslistURLs[which(craigslistURLs$region%in%c("US", "CA")),]

library(multicore)

samplecities <- sample(1:471, 50, replace=FALSE)
temp <- getCityPosts(samplecities[1], subcl="sss")
for(i in samplecities[2:length(samplecities)]){
  a <- getCityPosts(craigslistURLs[i,3], subcl="sss")
  if(is.data.frame(a)) temp <- rbind.fill(temp, a)
}

data <- read.csv("./CL-sss.csv", stringsAsFactors=TRUE)
data <- rbind.fill(data, temp)
data <- unique(data)
# stopped at 353 on the US/CA urls
write.csv(data, "CL-sss.csv", row.names=FALSE)