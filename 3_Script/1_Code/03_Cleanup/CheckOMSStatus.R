CheckOMSStatus <- function(invoiceData) {
suppressMessages({
    require(dplyr)
    require(tools)
    require(magrittr)
    require(methods)
    require(logging)
  })
  
  functionName <- "CheckOMSStatus"
  loginfo(paste("Function", functionName, "started"), logger = reportName)
  
  checkedStatus <- tryCatch({
    
    checkedStatus <- invoiceData %>%
      mutate(StatusCheck = ifelse(ExistenceCheck == "OKAY", 
                                  ifelse(is.na(Shipped_Date), "NO_SHIPPED","OKAY"), NA),
             PackageStatus = ifelse(!is.na(Delivered_Date), "DELIVERED",
                                    ifelse(!is.na(Cancelled_Date), "CANCELLED",
                                           ifelse(!is.na("Shipped_Date"), "SHIPPED", "NO_SHIPPED"))))
    
    for (iWarn in warnings()){
      logwarn(paste(functionName, iWarn), logger = reportName)
    }
    
    checkedStatus
    
  }, error = function(err) {
    logerror(paste(functionName, err, sep = " - "), logger = consoleLog)
  }, finally = {
    loginfo(paste(functionName, "ended"), logger = reportName)
  })
  
  checkedStatus
}