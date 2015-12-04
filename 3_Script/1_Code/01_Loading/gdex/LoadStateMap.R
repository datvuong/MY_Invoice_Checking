LoadStateMap <- function(stateMappingFile) {
  suppressMessages({
    require(dplyr)
    require(tidyr)
    require(magrittr)
    require(lubridate)
    require(logging)
  })
  
  functionName <- "LoadLocationMap"
  
  loginfo(paste0(functionName, " - Function Start"), logger = reportName)
  
  locationMapping <- read.csv(stateMappingFile,
                              quote = '"', sep=",", row.names = NULL,
                              col.names = c("state", "region"),
                              colClasses = c("character", "character"))
  
  loginfo(paste0(functionName, " - Function End"), logger = reportName)
  
  locationMapping
}