MapInvoiceOMSData <- function(invoiceData, OMSData) {
suppressMessages({
    require(dplyr)
    require(tools)
    require(magrittr)
    require(methods)
    require(logging)
  })
  
  functionName <- "MapInvoiceOMSData"
  loginfo(paste("Function", functionName, "started"), logger = reportName)
  
  InvoiceOMSMapped <- tryCatch({
    
    InvoiceOMSMapped <- left_join(invoiceData, OMSData,
                                  by = c("trackingNumber" = "tracking_number"))
    
    for (iWarn in warnings()){
      logwarn(paste(functionName, iWarn), logger = reportName)
    }
    
    InvoiceOMSMapped
    
  }, error = function(err) {
    logerror(paste(functionName, err, sep = " - "), logger = consoleLog)
  }, finally = {
    loginfo(paste(functionName, "Done Mapping Non LEX Cost Data"), logger = reportName)
  })
  
  InvoiceOMSMapped
}