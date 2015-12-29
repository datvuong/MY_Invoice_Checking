LoadLocationMap <- function(locationMappingFile) {
  suppressMessages({
    require(dplyr)
    require(tidyr)
    require(magrittr)
    require(lubridate)
    require(logging)
  })
  
  functionName <- "LoadLocationMap"
  
  loginfo(paste0(functionName, " - Function Start"), logger = reportName)
  
  locationMapping <- read.csv(locationMappingFile,
                              quote = '"', sep=",", row.names = NULL,
                              col.names = c("code", "branch", "name", "state", 
                                            "east_west", "destination"),
                              colClasses = c("character", "character", "character", "character", 
                                             "character", "character"))
  
  loginfo(paste0(functionName, " - Function End"), logger = reportName)
  
  locationMapping
}