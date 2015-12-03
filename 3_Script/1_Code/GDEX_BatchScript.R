dateReport <- format(Sys.time(), "%Y%m%d%H%M")
reportName <- "MY_InvoiceChecking"
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
                          paste0(reportName, "_", dateReport, ".csv"))
addHandler(writeToFile, logger = reportName, file = logFile)
consoleLog <- paste0(reportName,".console")
addHandler(writeToConsole, logger = consoleLog)

tryCatch({
  
  loginfo("Initial Setup", logger = reportName)
  source("3_Script/1_Code/01_Loading/fn_LoadOMSData.R")
  source("3_Script/1_Code/01_Loading/fn_LoadGDexInvoiceData.R")
  source("3_Script/1_Code/01_Loading/fn_LoadRateCards.R")
  source("3_Script/1_Code/01_Loading/fn_LoadLocationMap.R")
  source("3_Script/1_Code/03_Cleanup/MapInvoiceOMSData.R")
  
  omsDataFolder <- "1_Input/00_OMS_DATA"
  invoiceDataFodler <- "1_Input/01_gdex/new_invoices"
  rateCardFile <- "1_Input/01_gdex/rate_cards/gdex_ratecards.xlsx"
  locationMappingFile <- "1_Input/01_gdex/rate_cards/locationMapping.xlsx"
  
  loginfo("Loading Input Data", logger = consoleLog)
  loginfo("Loading OMS Data", logger = consoleLog)
  OMSData <- LoadOMSData(omsDataFolder)
  loginfo("Loading New Invoice Data", logger = consoleLog)
  invoiceData <- LoadGDexInvoiceData(invoiceDataFodler)
  loginfo("Loading Ratecard Data", logger = consoleLog)
  rateCard <- LoadRateCards(rateCardFile)
  locationMap <- LoadLocationMap(locationMappingFile)
  
  InvoiceOMSData <- MapInvoiceOMSData(invoiceData, OMSData)
  
})