LoadRateCards <- function(rateCardFile) {
  require(dplyr)
  require(tidyr)
  require(magrittr)
  require(lubridate)
  require(logging)
  require(XLConnect)
  
  functionName <- "LoadRateCards"
  
  loginfo(paste0(functionName, " - Function Start"), logger = reportName)
  
  wb <- loadWorkbook(rateCardFile)
  rateCard <- readWorksheet(wb, 1, header = TRUE)
  names(rateCard) <- c("origin", "destinaton", "state",
                       "origin_destination", "first_1kg",
                       "add_1kg","surcharge")
  
  loginfo(paste0(functionName, " - Function End"), logger = reportName)
  
  rateCard
}