LoadCommonVariables <- function(variablesFilePath) {
suppressMessages({
    require(dplyr)
    require(tools)
    require(magrittr)
    require(methods)
    require(logging)
  })
  
  functionName <- "LoadCommonVariables"
  loginfo(paste("Function", functionName, "started"), logger = reportName)
  
  commonVarialbes <- tryCatch({
    
    commonVarialbes <- read.csv(variablesFilePath, stringsAsFactors = FALSE)
    
    dimWeightFactor <<- commonVarialbes$value[1]
    singleItemTolerance <<- commonVarialbes$value[2]
    multipleItemsTolerance <<- commonVarialbes$value[3]
    weightDifferenceThreshold <<- commonVarialbes$value[4]
    feeDifferenceThreshold <<- commonVarialbes$value[5]
    
    for (iWarn in warnings()){
      logwarn(paste(functionName, iWarn), logger = reportName)
    }
    
    commonVarialbes
    
  }, error = function(err) {
    logerror(paste(functionName, err, sep = " - "), logger = consoleLog)
  }, finally = {
    loginfo(paste(functionName, "ended"), logger = reportName)
  })
  
  commonVarialbes
}