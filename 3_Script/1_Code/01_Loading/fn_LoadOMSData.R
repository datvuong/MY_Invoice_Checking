LoadOMSData <- function(omsDataFolder){
  
  suppressMessages({
  require(dplyr)
  require(tools)
  require(magrittr)
  require(methods)
  require(logging)
  })
  
  functionName <- "LoadOMSData"

  loginfo(paste0(functionName, " - Function Start"), logger = reportName)
  
  dateUpdate <- NULL
  for (file in list.files(omsDataFolder)){
    if(file_ext(file)=="csv") {
      dateModify <- file.mtime(file.path(omsDataFolder, file))
      if (is.null(dateUpdate)) {
        dateUpdate <- dateModify
      } else if (dateUpdate < dateModify) dateUpdate <- dateModify
    }
  }
  
  if(file.exists(file.path("3_Script/3_RData", "OMSData.RData")) &
     file.mtime(file.path("3_Script/3_RData", "OMSData.RData")) > dateUpdate) {
    loginfo("Load Old OMS Data", logger = consoleLog)
    load("3_Script/3_RData/OMSData.RData")
  } else {
    loginfo("Load New OMS Data", logger = consoleLog)
    setClass("myDateTime")
    setAs("character","myDateTime", function(from) as.POSIXct(gsub('"','',from), format="%Y-%m-%d %H:%M:%S"))
    setClass("myInteger")
    setAs("character","myInteger", function(from) as.integer(gsub('"','',from)))
    setClass("myNumeric")
    setAs("character","myNumeric", function(from) as.numeric(gsub('"','',from)))
    
    OMSData <- data.frame(order_nr = numeric(),
                             id_sales_order_item = numeric(),
                             bob_id_sales_order_item = numeric(),
                             SC_SOI_ID = numeric(),
                             business_unit = character(),
                             payment_method = character(),
                             sku = character(),
                             unit_price = numeric(),
                             paid_price = numeric(),
                             shipping_fee = numeric(),
                             shipping_surcharge = numeric(),
                             Item_Status = character(),
                             RTS_Date = as.POSIXct(character()),
                             Shipped_Date = as.POSIXct(character()),
                             Cancelled_Date = as.POSIXct(character()),
                             Delivered_Date = as.POSIXct(character()),
                             tracking_number = character(),
                             package_number = character(),
                             shipment_provider_name = character(),
                             Seller_Code = character(),
                             tax_class = character(),
                             shipping_city = character(),
                             shipping_region = character(),
                             package_length = numeric(),
                             package_width = numeric(),
                             package_height = numeric(),
                             package_weight = numeric())
    
    filesCount <- sum(grepl("\\.csv",list.files(omsDataFolder)))
    pb <- txtProgressBar(min=0,max=filesCount, style = 3)
    iProgress <- 0
    setTxtProgressBar(pb, iProgress)
    for (file in list.files(omsDataFolder)) {
      if(file_ext(file)=="csv"){
        tryCatch({
          currentFileData <- read.csv(file.path(omsDataFolder,file),
                                      quote = '"', sep=",", row.names = NULL,
                                      col.names=c("order_nr", "id_sales_order_item", "bob_id_sales_order_item",
                                                  "SC_SOI_ID", "business_unit", "payment_method",
                                                  "sku", "unit_price", "paid_price",
                                                  "shipping_fee", "shipping_surcharge", "Item_Status",
                                                  "RTS_Date", "Shipped_Date", "Cancelled_Date",
                                                  "Delivered_Date", "tracking_number", "package_number",
                                                  "shipment_provider_name", "Seller_Code", "tax_class",
                                                  "shipping_city", "shipping_region", "package_length",
                                                  "package_width", "package_height", "package_weight"),
                                      colClasses = c("myNumeric", "myNumeric", "myNumeric",
                                                     "myNumeric", "character", "character",
                                                     "character", "myNumeric", "myNumeric",
                                                     "myNumeric", "myNumeric", "character",
                                                     "myDateTime", "myDateTime", "myDateTime",
                                                     "myDateTime", "character", "character",
                                                     "character","character", "character",
                                                     "character","character", "myNumeric",
                                                     "myNumeric", "myNumeric", "myNumeric"))

          OMSData <- rbind_list(OMSData,currentFileData)
          
        }, warning = function(war) {
          logwarn(paste(functionName, war, sep = " - "), logger = reportName)
        }, error = function(err) {
          logerror(paste(functionName, err, sep = " - "), logger = consoleLog)
        })
        
        iProgress <- iProgress + 1
        setTxtProgressBar(pb, iProgress)
      }
    }
    
    cat("\r\n")
    
    #remove leading ZERO of tracking number to mapped with Invoice Data
    OMSData %<>%
      mutate(tracking_number=gsub("^0","",tracking_number))
    
    save(OMSData, file = "3_Script/3_RData/OMSData.RData")
  }
  
  loginfo(paste0(functionName, " - Function End"), logger = reportName)
  
  OMSData
}