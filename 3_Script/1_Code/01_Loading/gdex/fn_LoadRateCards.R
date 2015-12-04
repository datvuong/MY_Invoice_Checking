LoadRateCards <- function(rateCardFile) {
  suppressMessages({
    require(dplyr)
    require(tidyr)
    require(magrittr)
    require(lubridate)
    require(logging)
  })
  
  functionName <- "LoadRateCards"
  
  loginfo(paste0(functionName, " - Function Start"), logger = reportName)
  
  setClass("myInteger")
  setAs("character","myInteger", function(from) as.integer(gsub('"','',from)))
  setClass("myNumeric")
  setAs("character","myNumeric", function(from) as.numeric(gsub('"','',from)))
  
  rateCard <- read.csv(rateCardFile,
                       quote = '"', sep=",", row.names = NULL,
                       col.names = c("origin", "destinaton", "state",
                                     "origin_destination", "first_1kg", "add_1kg",
                                     "surcharge"),
                       colClasses = c("character", "character", "character",
                                      "character", "numeric", "numeric",
                                      "numeric"))
  
  loginfo(paste0(functionName, " - Function End"), logger = reportName)
  
  rateCard
}