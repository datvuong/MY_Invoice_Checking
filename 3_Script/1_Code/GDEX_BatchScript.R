dateReport <- format(Sys.time(), "%Y%m%d%H%M")
nameReport <- "MY_InvoiceChecking"
suppressMessages({
  # Set heap memory for Java upto 2GB
  options( java.parameters = "-Xmx2g") 
  library(dplyr)
  library(tidyr)
  library(magrittr)
  library(lubridate)
  library(logging)
  library(XLConnect)
})

logFile <- file.path("3_Script/2_Log",
                          paste0(nameReport, "_", dateReport, ".csv"))
addHandler(writeToFile, logger = nameReport, file = logFile)
consoleLog <- paste0(nameReport,".console")
addHandler(writeToConsole, logger = consoleLog)

tryCatch({
  
  loginfo("Initial Setup", logger = nameReport)
  source("3_Script/1_Code/01_Loading/fn_LoadOMSData.R")
  source("3_Script/1_Code/01_Loading/fn_LoadInvoiceData.R")
  
  omsDataFolder <- "1_Input/00_OMS_DATA"
  invoiceDataFodler <- "1_Input/01_gdex/new_invoices"
  rateCardFile <- "1_Input/01_gdex/rate_cards/gdex_ratecards.xlsx"
  locationMappingFile <- "1_Input/01_gdex/rate_cards/locationMapping.xlsx"
  
  loginfo("Loading Input Data", logger = consoleLog)
  loginfo("Load OMS Data", logger = consoleLog)
  OMSData <- LoadOMSData(omsDataFolder)
  loginfo("Load New Invoice Data", logger = consoleLog)
  invoiceData <- LoadGDexInvoiceData(invoiceDataFodler)
  rateCard <- LoadRateCards(rateCardFile)
  locationMap <- LoadLocationMap(locationMappingFile)
  
})
