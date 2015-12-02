LoadLocationMap <- function(locationMappingFile) {
  require(dplyr)
  require(tidyr)
  require(magrittr)
  require(lubridate)
  require(logging)
  require(XLConnect)
  
  functionName <- "LoadRateCards"
  
  loginfo(paste0(functionName, " - Function Start"), logger = reportName)
  
  wb <- loadWorkbook(locationMappingFile)
  locationMapping <- readWorksheet(wb, 1, header = TRUE)
  names(locationMapping) <- c("code", "branch", "name",
                              "state", "region", "destination")
  
  loginfo(paste0(functionName, " - Function End"), logger = reportName)
  
  locationMapping
}