MapInvoiceOMSData <- function(invoiceData, OMSData, dimWeightFactor, singleItemTolerance,
                              multipleItemsTolerance) {
  suppressMessages({
    require(dplyr)
    require(tools)
    require(magrittr)
    require(methods)
    require(logging)
  })
  
  functionName <- "MapInvoiceOMSData"
  loginfo(paste("Function", functionName, "started"), logger = reportName)
  
  invoiceOMSMapped <- tryCatch({
    
    OMSData %<>%
      mutate(actualWeight = package_weight) %>%
      mutate(volumetricWeight = volumetricDimension / dimWeightFactor) %>%
      mutate(finalWeight = ifelse(actualWeight > volumetricWeight, actualWeight,
                                  volumetricWeight) * singleItemTolerance) 
    
    OMSDataTrackingFinal <-  OMSData %>%
      select(order_nr, tracking_number, 
             unit_price, paid_price, shippingFee, shippingSurcharge,
             skus_names, actualWeight, volumetricWeight, 
             finalWeight, RTS_Date = rts, Shipped_Date = shipped,
             Cancelled_Date = cancelled, Delivered_Date = delivered, payment_method, 
             shipment_provider_name, level_2_name, level_3_name, level_4_name,
             Seller_Code, Seller, tax_class)
    
    invoiceOMSMapped <- left_join(invoiceData, OMSDataTrackingFinal,
                                  by = c("trackingNumber" = "tracking_number"))

    for (iWarn in warnings()){
      logwarn(paste(functionName, iWarn), logger = reportName)
    }
    
    invoiceOMSMapped
    
  }, error = function(err) {
    logerror(paste(functionName, err, sep = " - "), logger = consoleLog)
  }, finally = {
    loginfo(paste(functionName, "Done Mapping Non LEX Cost Data"), logger = reportName)
  })
  
  invoiceOMSMapped
}