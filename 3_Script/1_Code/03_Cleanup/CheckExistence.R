CheckExistence <- function(invoiceData) {
suppressMessages({
    require(dplyr)
    require(tools)
    require(magrittr)
    require(methods)
    require(logging)
  })
  
  functionName <- "CheckExistence"
  loginfo(paste("Function", functionName, "started"), logger = reportName)
  
  checkedInvoice <- tryCatch({
    
    checkedInvoice <- invoiceData %>%
      mutate(ExistenceCheck = ifelse(!is.na(order_nr), "OKAY", "NOT_FOUND"))
    
    for (iWarn in warnings()){
      logwarn(paste(functionName, iWarn), logger = reportName)
    }
    
    checkedInvoice
    
  }, error = function(err) {
    logerror(paste(functionName, err, sep = " - "), logger = consoleLog)
  }, finally = {
    loginfo(paste(functionName, "ended"), logger = reportName)
  })
  
  checkedInvoice
}