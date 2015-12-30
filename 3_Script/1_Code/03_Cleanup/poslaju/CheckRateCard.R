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
      rename(destinationZone = destinationBranch) %>%
      mutate(destinationZone = toupper(trimws(destinationZone)))
    
    rateCardData <- rateCard %>%
      select(zone,first_5kg, add_1kg,first_500g,add_250g,from2kg_2.5kg,add_500g,surcharge) %>%
      mutate(uniqueKey = toupper(trimws(zone))) %>%
      filter(!duplicated(uniqueKey))
#     rateCardData <- rateCardData %>%
#       mutate(uniqueKey = paste(origin, destinaton, sep = "/")) %>%
#       filter(!duplicated(uniqueKey))
    
    rateCardChecked %<>%
      left_join(rateCardData, by = c("destinationZone" = "uniqueKey"))
    
    rateCardChecked %<>%
      mutate(calculatedWeight = ifelse(is.na(finalWeight), packageChargeableWeight, finalWeight)) %>%
      mutate(lazadaCalFee = ifelse((destinationZone == "1") || (destinationZone == "2") , 
                                   (first_5kg + ceiling(pmax((calculatedWeight - 5), 0)) * add_1kg), 
                                   (ifelse(calculatedWeight < 2,
                                            first_500g + ceiling(pmax((calculatedWeight - 0.5),0)/0.25) * add_250g, 
                                            from2kg_2.5kg + ceiling(pmax((calculatedWeight - 2.5),0)/0.5) * add_500g))) * (1 + surcharge))
    
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