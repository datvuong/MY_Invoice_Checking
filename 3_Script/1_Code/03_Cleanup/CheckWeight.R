CheckWeight <- function(invoideData, weightDifferenceThreshold) {
suppressMessages({
    require(dplyr)
    require(tools)
    require(magrittr)
    require(methods)
    require(logging)
  })
  
  functionName <- "CheckWeight"
  loginfo(paste("Function", functionName, "started"), logger = reportName)
  
  checkedInvoice <- tryCatch({
    
    checkedInvoice <- invoideData %>%
      mutate(weightDifference = packageChargeableWeight - finalWeight,
             weightCheck = ifelse(weightDifference > weightDifferenceThreshold,
                                  "EXCEED_THRESHOLD", "OKAY"))
    
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