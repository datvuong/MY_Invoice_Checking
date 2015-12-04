dateReport <- format(Sys.time(), "%Y%m%d%H%M")
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

tryCatch({
  
  loginfo("Initial Setup", logger = reportName)
  source("3_Script/1_Code/01_Loading/fn_LoadOMSData.R")
  source("3_Script/1_Code/01_Loading/fn_LoadInvoiceData.R")
  source("3_Script/1_Code/01_Loading/gdex/fn_LoadRateCards.R")
  source("3_Script/1_Code/01_Loading/gdex/fn_LoadLocationMap.R")
  source("3_Script/1_Code/01_Loading/gdex/LoadStateMap.R")
  source("3_Script/1_Code/01_Loading/gdex/LoadCommonVariables.R")
  
  source("3_Script/1_Code/03_Cleanup/MapInvoiceOMSData.R")
  source("3_Script/1_Code/03_Cleanup/CheckExistence.R")
  source("3_Script/1_Code/03_Cleanup/CheckDuplication.R")
  source("3_Script/1_Code/03_Cleanup/CheckOMSStatus.R")
  source("3_Script/1_Code/03_Cleanup/CheckCODFee.R")
  source("3_Script/1_Code/03_Cleanup/CheckWeight.R")
  source("3_Script/1_Code/03_Cleanup/gdex/CheckRateCard.R")

  source("5_Script/1_Code/05_Reports/SummaryReport.R")
  source("5_Script/1_Code/05_Reports/OutputRawData.R")
  
  variableFilePath <- "1_Input/01_gdex/commonVariables.csv"
  omsDataFolder <- "1_Input/00_OMS_DATA"
  invoiceDataFolder <- "1_Input/01_gdex/new_invoices"
  oldInvoiceDataFolder <- "1_Input/01_gdex/old_invoices"
  rateCardFile <- "1_Input/01_gdex/rate_cards/gdex_ratecards.csv"
  locationMappingFile <- "1_Input/01_gdex/rate_cards/locationMapping.csv"
  stateMappingFile <- "1_Input/01_gdex/rate_cards/stateMapping.csv"
  
  loginfo("Loading Input Data", logger = consoleLog)
  loginfo("Loading OMS Data", logger = consoleLog)
  OMSData <- LoadOMSData(omsDataFolder)
  loginfo("Loading New Invoice Data", logger = consoleLog)
  newInvoiceData <- LoadInvoiceData(invoiceDataFolder)
  oldInvoiceData <- LoadInvoiceData(oldInvoiceDataFolder)
  loginfo("Loading Ratecard Data", logger = consoleLog)
  rateCard <- LoadRateCards(rateCardFile)
  locationMap <- LoadLocationMap(locationMappingFile)
  stateMap <- LoadStateMap(stateMappingFile)
  
  LoadCommonVariables(variableFilePath)
  
  loginfo("Mapping Invoice with OMS Data - This would take around 15 mins", logger = consoleLog)
  invoiceOMSData <- MapInvoiceOMSData(newInvoiceData, OMSData, dimWeightFactor,
                                      singleItemTolerance, multipleItemsTolerance)
  
  checkedInvoiceData <- CheckExistence(invoiceOMSData)
  checkedInvoiceData <- CheckDuplication(checkedInvoiceData, oldInvoiceData)
  checkedInvoiceData <- CheckOMSStatus(checkedInvoiceData)
  checkedInvoiceData <- CheckCODFee(checkedInvoiceData)
  checkedInvoiceData <- CheckWeight(checkedInvoiceData, weightDifferenceThreshold)
  checkedInvoiceData <- CheckRateCard(checkedInvoiceData, rateCard, locationMap,
                                      stateMap, feeDifferenceThreshold)
  
  finalOutput <- checkedInvoiceData %>%
    select(deliveryCompany, pacagePickupDate, pacagePODDate,
           invoiceNumber, packageNumber, trackingNumber,
           trackingNumberRTS, order_nr, packageChargeableWeight,
           lazadaWeight = actualWeight, lazadaDimWeight = volumetricWeight,
           carryingFee, redeliveryFee, rejectionFee, CODFee, specialAreaFee,
           specialHandlingFee, insuranceFee, lazadaCalFee, feeSuggested, originBranch,
           destinationBranch, deliveryZoneZipCode, rateType, skus, ExistenceCheck, 
           duplicatedFlag, duplicatedFile, StatusCheck, weightDifference, weightCheck,
           rateCardCheck)
  
  finalOutput %<>%
    mutate(manualCheck = ifelse(ExistenceCheck != "OKAY", ExistenceCheck,
                                ifelse(duplicatedFlag != "OKAY", duplicatedFlag,
                                       ifelse(StatusCheck != "OKAY", StatusCheck,
                                              ifelse(weightCheck != "OKAY", weightCheck,
                                                     ifelse(rateCardCheck != "OKAY", rateCardCheck, "OKAY"))))))
  
  OutputRawData(finalOutput, paste0("2_Output/gdex/checkedInvoice_",dateReport,".csv"))
  SummaryReport(finalOutput, paste0("2_Output/gdex/summaryReport_",dateReport,".csv"))
    
}, error = function(err) {
  logerror(paste("Main Script", err), logger = consoleLog)
}, finally = {
  loginfo("Done Invoice Checking!!!", logger = consoleLog)
})