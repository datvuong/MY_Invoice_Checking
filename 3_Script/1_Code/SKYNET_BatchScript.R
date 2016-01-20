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
  source("3_Script/1_Code/01_Loading/skynet/fn_LoadRateCards.R")
  source("3_Script/1_Code/01_Loading/skynet/fn_LoadLocationMap.R")
  source("3_Script/1_Code/01_Loading/skynet/LoadStateMap.R")
  source("3_Script/1_Code/01_Loading/skynet/LoadCommonVariables.R")
  
  source("3_Script/1_Code/03_Cleanup/MapInvoiceOMSData.R")
  source("3_Script/1_Code/03_Cleanup/CheckExistence.R")
  source("3_Script/1_Code/03_Cleanup/CheckDuplication.R")
  source("3_Script/1_Code/03_Cleanup/CheckOMSStatus.R")
  source("3_Script/1_Code/03_Cleanup/CheckCODFee.R")
  source("3_Script/1_Code/03_Cleanup/CheckWeight.R")
  source("3_Script/1_Code/03_Cleanup/skynet/CheckRateCard.R")

  source("3_Script/1_Code/05_Reports/SummaryReport.R")
  source("3_Script/1_Code/05_Reports/OutputRawData.R")
  
  variableFilePath <- "1_Input/02_skynet/commonVariables.csv"
  omsDataFolder <- "1_Input/00_OMS_DATA"
  invoiceDataFolder <- "1_Input/02_skynet/new_invoices"
  oldInvoiceDataFolder <- "1_Input/02_skynet/old_invoices"
  rateCardFile <- "1_Input/02_skynet/rate_cards/skynet_ratecards.csv"
  locationMappingFile <- "1_Input/02_skynet/rate_cards/locationMapping.csv"
  stateMappingFile <- "1_Input/02_skynet/rate_cards/stateMapping.csv"
  
  loginfo("Loading Input Data", logger = consoleLog)
  loginfo("Loading OMS Data", logger = consoleLog)
  load("1_Input/RData/packageDataBased.RData")
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
           trackingNumberRTS, order_nr, packageChargeableWeight, PackageStatus,
           lazadaWeight = actualWeight, lazadaDimWeight = volumetricWeight,
           carryingFee, redeliveryFee, rejectionFee, CODFee, specialAreaFee,
           specialHandlingFee, insuranceFee, lazadaCalFee, feeSuggested, originBranch,
           destinationBranch, deliveryZoneZipCode, rateType, skus_names, Seller_Code, ExistenceCheck, 
           duplicatedFlag, duplicatedFile, StatusCheck, weightDifference, weightCheck,
           rateCardCheck)
  
  finalOutput %<>%
    mutate(manualCheck = ifelse(ExistenceCheck != "OKAY", ExistenceCheck,
                                ifelse(duplicatedFlag != "OKAY", duplicatedFlag,
                                       ifelse(StatusCheck != "OKAY", StatusCheck,
                                              ifelse(weightCheck != "OKAY", weightCheck,
                                                     ifelse(rateCardCheck != "OKAY", rateCardCheck, "OKAY"))))))

  exceedThresholdTrackingNumber <- finalOutput %>%
    filter(manualCheck == "EXCEED_THRESHOLD") %>%
    select(deliveryCompany, trackingNumber, packageChargeableWeight, packageChargeableWeight, carryingFee,
           lazadaWeight, lazadaDimWeight, lazadaCalFee)

  notFoundTrackingNumber <- finalOutput %>%
    filter(manualCheck == "NOT_FOUND") %>%
    select(deliveryCompany, trackingNumber, Seller_Code)
  
  OutputRawData(finalOutput, paste0("2_Output/skynet/checkedInvoice_",dateReport,".csv"))
  OutputRawData(exceedThresholdTrackingNumber, paste0("2_Output/skynet/exceedThresholdTrackingNumber_",dateReport,".csv"))
  OutputRawData(notFoundTrackingNumber, paste0("2_Output/skynet/notFoundTrackingNumber_",dateReport,".csv"))
  SummaryReport(finalOutput, paste0("2_Output/skynet/summaryReport_",dateReport,".csv"))
    
}, error = function(err) {
  logerror(paste("Main Script", err), logger = consoleLog)
}, finally = {
  loginfo("Done Invoice Checking!!!", logger = consoleLog)
})