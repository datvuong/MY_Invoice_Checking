dateReport <- format(Sys.time(), "%Y%m%d%H")
reportName <- "MY_InvoiceChecking"
suppressMessages({
  options(scipen=999)
  library(dplyr)
  library(tidyr)
  library(magrittr)
  library(lubridate)
  library(logging)
  library(tools)
})

logFile <- file.path("3_Script/2_Log",
                     paste0(reportName, "_", dateReport, ".csv"))
addHandler(writeToFile, logger = reportName, file = logFile)
consoleLog <- paste0(reportName,".console")
addHandler(writeToConsole, logger = consoleLog)