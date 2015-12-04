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
    
    pb <- txtProgressBar(min=0,max=8, style = 3)
    iProgress <- 0
    setTxtProgressBar(pb, iProgress)
    
    OMSDataNoDup <- OMSData %>%
      mutate(uniqueKey = paste0(tracking_number, id_sales_order_item)) %>%
      arrange(desc(Shipped_Date), desc(Delivered_Date), desc(Cancelled_Date)) %>%
      filter(!duplicated(uniqueKey))
    
    iProgress <- iProgress + 1
    setTxtProgressBar(pb, iProgress)
    
    OMSDataTracking <- OMSDataNoDup %>% 
      group_by(tracking_number) %>%
      mutate(itemsCount = n_distinct(id_sales_order_item)) %>%
      mutate(unitPrice = sum(unit_price)) %>%
      mutate(paidPrice = sum(paid_price)) 
    
    iProgress <- iProgress + 1
    setTxtProgressBar(pb, iProgress)
    
    OMSDataTracking %<>%
      mutate(shippingFee = sum(shipping_fee)) %>%
      mutate(shippingSurcharge = sum(shipping_surcharge)) %>%
      mutate(skus = paste(sku, collapse = "/")) 
    
    iProgress <- iProgress + 1
    setTxtProgressBar(pb, iProgress)
    
    OMSDataTracking %<>%
      mutate(actualWeight = sum(package_weight)) %>%
      mutate(volumetricWeight = sum((package_length * package_width * package_height) / dimWeightFactor)) %>%
      mutate(finalWeight = ifelse(actualWeight > volumetricWeight, actualWeight,
                                  volumetricWeight) *
               (1 + ifelse(itemsCount == 1, singleItemTolerance, multipleItemsTolerance))) 
    
    iProgress <- iProgress + 1
    setTxtProgressBar(pb, iProgress)
    
    iProgress <- iProgress + 1
    setTxtProgressBar(pb, iProgress)
    
    OMSDataTracking %<>%
      mutate(RTS_Date = last(RTS_Date)) %>%
      mutate(Shipped_Date = last(Shipped_Date)) %>%
      mutate(Cancelled_Date = last(Cancelled_Date)) %>%
      mutate(Delivered_Date = last(Delivered_Date)) %>%
      ungroup()
    
    iProgress <- iProgress + 1
    setTxtProgressBar(pb, iProgress)
    
    OMSDataTrackingFinal <-  OMSDataTracking %>%
      select(order_nr, tracking_number, itemsCount,
             unitPrice, paidPrice, shippingFee, shippingSurcharge,
             skus, actualWeight, volumetricWeight, 
             finalWeight, RTS_Date, Shipped_Date,
             Cancelled_Date, Delivered_Date, payment_method, 
             Seller_Code, tax_class) %>%
      filter(!duplicated(tracking_number))
    
    iProgress <- iProgress + 1
    setTxtProgressBar(pb, iProgress)
    
    invoiceOMSMapped <- left_join(invoiceData, OMSDataTrackingFinal,
                                  by = c("trackingNumber" = "tracking_number"))
    
    iProgress <- iProgress + 1
    setTxtProgressBar(pb, iProgress)
    
    cat("\r\n")

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