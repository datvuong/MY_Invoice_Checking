source("3_Script/1_Code/fn_loadRatecards.R")
source("3_Script/1_Code/fn_loadInvoiceData.R")
source("3_Script/1_Code/fn_loadOMSData.R")
source("3_Script/1_Code/fn_loadPaidInvoice.R")
source("3_Script/1_Code/fn_GeneratePackageData.R")

loginfo("Loading ratecard data...", logger = "IDInvoiceCheck.Log")
rateCard <- loadRateCards("1_Input/Ratecards/JNE_Ratecards.csv")
loginfo("Loading OMS data...", logger = "IDInvoiceCheck.Log")
dateUpdate <- NULL
for (file in list.files("1_Input/OMS_Data/")){
  if(file_ext(file)=="csv") {
    dateModify <- file.mtime(file.path("1_Input/OMS_Data",file))
    if (is.null(dateUpdate)){
      dateUpdate <- dateModify
    } else if (dateUpdate < dateModify) dateUpdate <- dateModify
  }
}
if(file.exists(file.path("3_Script/3_RData", "OMSData.RData")) &
   file.mtime(file.path("3_Script/3_RData", "OMSData.RData")) > dateUpdate) {
  load("3_Script/3_RData/OMSData.RData")
  load("3_Script/3_RData/PackageDataSummarized.RData")
}else{
  OMSData <- LoadOMSData(OMSDataFolder)
  PackageDataSummarized <- GeneratePackageData(OMSData)
  save(OMSData, file = "3_Script/3_RData/OMSData.RData")
  save(PackageDataSummarized, file = "3_Script/3_RData/PackageDataSummarized.RData")
}

##### Match Invoice Data with OMS Data #####
paidDeliveryInvoiceData <- loadPaidDeliveryInvoiceData("1_Input/Paid_Invoice/DELIVERY_INSURANCE")
loginfo("Start Verify Delivery & Insruance invoices data...", logger = "IDInvoiceCheck.Log")
DeliveryInvoice <- file.path("1_Input/Invoice","DELIVERY_INSURANCE")
filesCount <- sum(grepl("\\.csv",list.files(DeliveryInvoice)))
pb <- txtProgressBar(min=0,max=filesCount, style = 3)
iProgress <- 0
setTxtProgressBar(pb, iProgress)
for (iFile in list.files(DeliveryInvoice)){
  if (file_ext(iFile)=="csv"){
    loginfo(paste0("--- Start Processing Invoice File: ",iFile), logger = "IDInvoiceCheck")
    invoiceData <- loadDeliveryInvoiceData(file.path(DeliveryInvoice,iFile))
    #cat(paste0("----- Duplicated Invoice Data: ", sum(duplicated(invoiceData$tracking_number)),"\r\n"))
    
    invoiceTracking <- unique(invoiceData$tracking_number)
    PackageDataToMapped <- filter(PackageDataSummarized,
                                  tracking_number %in% invoiceTracking)
    
    InvoiceMapped <- left_join(invoiceData, PackageDataToMapped,
                               by=("tracking_number"))
    
    OMS_OrderList <- unique(OMSData$order_nr)
    
    InvoiceMapped %<>%
      mutate(OrderExisted=ifelse(!is.na(order_nr) |
                                   Order_Nr %in% OMS_OrderList,"Existed","Not-Existed"))
    
    ##### Ratecard Calculation #####
    InvoiceMappedRate <- left_join(InvoiceMapped, rateCard,
                                   by=c("Destination_Code"="Coding"))
    
    paidInvoice <- paidDeliveryInvoiceData$tracking_number
    paidInvoiceList <- select(paidDeliveryInvoiceData, tracking_number,InvoiceFile)
    row.names(paidInvoiceList) <- paidInvoiceList$tracking_number
    
    InvoiceMappedRate %<>%
      mutate(FrieghtCost_Calculate=TARIF * Weight,
             InsuranceFee_Calculate=ifelse(COD_Amount < 1000000,2500,
                                           0.0025 * COD_Amount)) %>%
      mutate(FrieghtCost_Flag=ifelse(Amount - FrieghtCost_Calculate < 1,"Okay","Not-Okay")) %>%
      mutate(InsuranceFee_Flag=ifelse(Insurance - InsuranceFee_Calculate < 1,"Okay","Not-Okay")) %>%
      mutate(Duplication_Flag=ifelse(duplicated(tracking_number),"Duplicated",
                                     ifelse(tracking_number %in% paidInvoice,
                                            "Duplicated","Not_Duplicated"))) %>%
      mutate(DuplicationSource=ifelse(duplicated(tracking_number),"Self_Duplicated",
                                      ifelse(tracking_number %in% paidInvoice,
                                             paidInvoiceList[tracking_number,]$InvoiceFile,"")))
    InvoiceMappedRate %<>%
      mutate(Order_Nr = ifelse(is.na(Order_Nr) & !is.na(order_nr),
                               order_nr, Order_Nr))
    InvoiceMappedRate %<>%
      select(tracking_number, TGL_ENTRY, Order_Nr,
             Destination_Code, Qty, Weight,
             GOOD_Values, Insurance, Amount, 
             Instruction, Service, Status,
             OrderExisted,FrieghtCost_Calculate,InsuranceFee_Calculate,
             FrieghtCost_Flag,InsuranceFee_Flag,
             Duplication_Flag,DuplicationSource,
             order_nr, business_unit, payment_method,
             Total_unit_price,COD_Amount, RTS_Date,
             Shipped_Date, Cancelled_Date, Delivered_Date,
             tracking_number, shipment_provider_name,
             Seller_Code, tax_class,
             shipping_city, shipping_region)
    
    fileName <- gsub('\\.csv','',iFile)
    
    ##### Output #####
    write.csv2(InvoiceMappedRate, file.path("2_Output/DELIVERY_INSURANCE",paste0(fileName,'_checked.csv')),
               row.names = FALSE)
    
    loginfo(paste0("--- Done Processing Invoice File: ",iFile), logger = "IDInvoiceCheck")
    iProgress <- iProgress + 1
    setTxtProgressBar(pb, iProgress)
  }
}
cat("\r\n")
loginfo("Start Verify COD invoices data...", logger = "IDInvoiceCheck.Log")
paidCODInvoiceData <- loadPaidCODInvoiceData("1_Input/Paid_Invoice/COD")
CODInvoice <- file.path("1_Input/Invoice","COD")
filesCount <- sum(grepl("\\.csv",list.files(CODInvoice)))
pb <- txtProgressBar(min=0,max=filesCount, style = 3)
iProgress <- 0
setTxtProgressBar(pb, iProgress)
for (iFile in list.files(CODInvoice)){
  if (file_ext(iFile)=="csv"){
    loginfo(paste0("--- Start Processing Invoice File: ",iFile), logger = "IDInvoiceCheck")
    invoiceData <- loadCODInvoiceData(file.path(CODInvoice,iFile))
    #cat(paste0("----- Duplicated Invoice Data: ", sum(duplicated(invoiceData$tracking_number)),"\r\n"))
    
    invoiceTracking <- unique(invoiceData$tracking_number)
    PackageDataToMapped <- filter(PackageDataSummarized,
                                  tracking_number %in% invoiceTracking)
    
    InvoiceMapped <- left_join(invoiceData, PackageDataToMapped,
                               by=("tracking_number"))
    
    OMS_OrderList <- unique(OMSData$order_nr)
    
    InvoiceMapped %<>%
      mutate(OrderExisted=ifelse(!is.na(order_nr) |
                                   Order_Nr %in% OMS_OrderList,"Existed","Not-Existed"))
    
    paidInvoice <- paidCODInvoiceData$tracking_number
    paidInvoiceList <- select(paidCODInvoiceData, tracking_number,InvoiceFile)
    row.names(paidInvoiceList) <- paidInvoiceList$tracking_number
    
    InvoiceMapped %<>%
      mutate(COD_Fee_Calculated=ifelse(payment_method=="CashOnDelivery" &
                                         !is.na(Delivered_Date),
                                       0.01 * COD_Amount,0)) %>%
      mutate(COD_Flag=ifelse(COD_Fee_Calculated >= Management_Fee,
                             "Okay", "Not-Okay")) %>%
      mutate(Duplication_Flag=ifelse(duplicated(tracking_number),"Duplicated",
                                     ifelse(tracking_number %in% paidInvoice,
                                            "Duplicated","Not_Duplicated"))) %>%
      mutate(DuplicationSource=ifelse(duplicated(tracking_number),"Self_Duplicated",
                                      ifelse(tracking_number %in% paidInvoice,
                                             paidInvoiceList[tracking_number,]$InvoiceFile,"Not_Duplicated")))
    
    InvoiceMapped %<>%
      mutate(Order_Nr = ifelse(is.na(Order_Nr) & !is.na(order_nr),
                               order_nr, Order_Nr))
    InvoiceMapped %<>%
      select(tracking_number, TGL_ENTRY, Order_Nr,
             Destination_Code, Qty, Weight,
             GOOD_Values, Management_Fee, Instruction, 
             Service, Status, OrderExisted,
             COD_Fee_Calculated, COD_Flag,
             Duplication_Flag, DuplicationSource,
             order_nr, business_unit, payment_method,
             Total_unit_price,COD_Amount, RTS_Date,
             Shipped_Date, Cancelled_Date, Delivered_Date,
             tracking_number, shipment_provider_name,
             Seller_Code, tax_class,
             shipping_city, shipping_region)
    
    ##### Output #####
    write.csv2(InvoiceMapped, file.path("2_Output/COD",iFile),
               row.names = FALSE)
    loginfo(paste0("--- Done Processing Invoice File: ",iFile), logger = "IDInvoiceCheck")
    iProgress <- iProgress + 1
    setTxtProgressBar(pb, iProgress)
  }
}
cat("\r\n")
loginfo(paste0("--- Done!!!"), logger = "IDInvoiceCheck.Log")
loginfo(paste0(warnings()), logger = "IDInvoiceCheck")
},error = function(err){
  logerror(err, logger = "IDInvoiceCheck")
  logerror("PLease send 3_Script/Log folder to Regional OPS BI for additional support",
           logger = "IDInvoiceCheck.Log")