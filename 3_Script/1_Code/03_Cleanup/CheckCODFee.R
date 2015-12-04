CheckCODFee <- function(invoiceData) {
suppressMessages({
    require(dplyr)
    require(tools)
    require(magrittr)
    require(methods)
    require(logging)
  })
  
  functionName <- "CheckCODFee"
  loginfo(paste("Function", functionName, "started"), logger = reportName)
  
  checkedCODFee <- tryCatch({
    
    checkedCODFee <- invoiceData
    
    for (iWarn in warnings()){
      logwarn(paste(functionName, iWarn), logger = reportName)
    }
    
    checkedCODFee
    
  }, error = function(err) {
    logerror(paste(functionName, err, sep = " - "), logger = consoleLog)
  }, finally = {
    loginfo(paste(functionName, "ended"), logger = reportName)
  })
  
  checkedCODFee
}