CheckDuplication <- function(newInvoiceData, oldInvoiceData) {
  suppressMessages({
    require(tidyr)
    require(dplyr)
    require(tools)
    require(magrittr)
    require(methods)
    require(logging)
  })
  
  functionName <- "CheckDuplication"
  loginfo(paste("Function", functionName, "started"), logger = reportName)
  
  duplcationChecked <- tryCatch({
    
    oldTrackingData <- oldInvoiceData %>%
      select(trackingNumber, duplicatedFile=invoiceFile)
    
    duplcationChecked <- left_join(newInvoiceData, oldTrackingData,
                                   by = "trackingNumber")
    
    duplcationChecked %<>%
      replace_na(list(duplicatedFile = "")) %>%
      mutate(duplicatedFlag = ifelse(duplicatedFile == "", "OKAY", "DUPLICATED"))
    
    
    for (iWarn in warnings()){
      logwarn(paste(functionName, iWarn), logger = reportName)
    }
    
    duplcationChecked
    
  }, error = function(err) {
    logerror(paste(functionName, err, sep = " - "), logger = consoleLog)
  }, finally = {
    loginfo(paste(functionName, "ended"), logger = reportName)
  })
  
  duplcationChecked
}