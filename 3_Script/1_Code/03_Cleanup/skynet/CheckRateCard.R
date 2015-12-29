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
    
#     stateMap <- stateMap %>%
#       mutate(state = toupper(trimws(state))) %>%
#       mutate(east_west = toupper(trimws(east_west)))
#     originMapping <- locationMap %>%
#       select(code, east_west) %>%
#       mutate(east_west = toupper(trimws(east_west))) 
    origDestMapping <- locationMap %>%
      select(code, east_west) %>%
      filter(!duplicated(code)) %>%
      mutate(east_west = toupper(trimws(east_west)))
    
    rateCardChecked <- invoiceData
    rateCardChecked %<>%
      left_join(origDestMapping, by = c("originBranch" = "code")) %>%
      rename(originRegion = east_west) %>%
      mutate(originRegion = toupper(trimws(originRegion))) %>%
      left_join(origDestMapping, by = c("destinationBranch" = "code")) %>%
      rename(destinationRegion = east_west) %>%
      mutate(destinationRegion = toupper(trimws(destinationRegion)))
    
    rateCardData <- rateCard %>%
      select(state, east_west, first_1kg,
             add_1kg, surcharge) %>%
      mutate(uniqueKey = toupper(trimws(east_west))) %>%
      filter(!duplicated(uniqueKey))
#     rateCardData <- rateCardData %>%
#       mutate(uniqueKey = paste(origin, destinaton, sep = "/")) %>%
#       filter(!duplicated(uniqueKey))
    
    rateCardChecked %<>%
      mutate(rateCardUnique = paste(originRegion, destinationRegion, sep = "/")) %>%
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