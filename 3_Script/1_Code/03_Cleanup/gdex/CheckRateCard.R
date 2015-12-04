CheckRateCard <- function(invoiceData, rateCard, locationMap, stateMap,
                          feeDifferenceThreshold) {
  suppressMessages({
    require(dplyr)
    require(tools)
    require(magrittr)
    require(methods)
    require(logging)
  })
  
  functionName <- "CheckRateCard"
  loginfo(paste("Function", functionName, "started"), logger = reportName)
  
  rateCardChecked <- tryCatch({
    
    originMapping <- locationMap %>%
      select(code, state) %>%
      left_join(stateMap, by = "state")
    destMapping <- locationMap %>%
      select(code, branch) %>%
      filter(!duplicated(code)) %>%
      mutate(branch = toupper(trimws(branch)))
    
    rateCardChecked <- invoiceData
    rateCardChecked %<>%
      left_join(originMapping, by = c("originBranch" = "code")) %>%
      rename(originRegion = region) %>%
      mutate(originRegion = toupper(trimws(originRegion))) %>%
      left_join(destMapping, by = c("destinationBranch" = "code"))
    
    rateCardData <- rateCard %>%
      select(origin, destinaton, first_1kg,
             add_1kg, surcharge) %>%
      mutate(destinaton = toupper(trimws(destinaton))) %>%
      mutate(origin = toupper(trimws(origin)))
    rateCardData <- rateCardData %>%
      mutate(uniqueKey = paste(origin, destinaton, sep = "/")) %>%
      filter(!duplicated(uniqueKey))
    
    rateCardChecked %<>%
      mutate(rateCardUnique = paste(originRegion, branch, sep = "/")) %>%
      left_join(rateCardData, by = c("rateCardUnique" = "uniqueKey"))
    
    rateCardChecked %<>%
      mutate(lazadaCalFee = (first_1kg + 
                               (round(ifelse(is.na(finalWeight), 
                                             packageChargeableWeight, finalWeight)
                                      + 0.5, 1) - 1) * add_1kg) *
               (1 + surcharge))
    
    rateCardChecked %<>%
      mutate(feeSuggested = ifelse(carryingFee - lazadaCalFee > feeDifferenceThreshold,
                                   lazadaCalFee, carryingFee)) %>%
      mutate(feeSuggested = ifelse(is.na(feeSuggested), carryingFee, feeSuggested)) %>%
      mutate(rateCardCheck = ifelse(carryingFee - lazadaCalFee > feeDifferenceThreshold,
                                    "EXCEED_THRESHOLD", "OKAY"))
    
    for (iWarn in warnings()){
      logwarn(paste(functionName, iWarn), logger = reportName)
    }
    
    rateCardChecked
    
  }, error = function(err) {
    logerror(paste(functionName, err, sep = " - "), logger = consoleLog)
  }, finally = {
    loginfo(paste(functionName, "ended"), logger = reportName)
  })
  
  rateCardChecked
}