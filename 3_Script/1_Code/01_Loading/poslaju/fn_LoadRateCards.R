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
                       col.names = c("origin_state", "destination_state","zone", "first_5kg", 
                                     "add_1kg", "first_500g", "add_250g", "from2kg_2.5kg", 
                                     "add_500g", "surcharge"),
                       colClasses = c("character","character","character","numeric", 
                                      "numeric", "numeric","numeric", "numeric",
                                      "numeric","numeric"))
  
  loginfo(paste0(functionName, " - Function End"), logger = reportName)
  
  rateCard
}