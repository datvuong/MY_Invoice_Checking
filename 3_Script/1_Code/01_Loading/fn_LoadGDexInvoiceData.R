LoadGDexInvoiceData <- function(invoicePath) {
  require(dplyr)
  require(tidyr)
  require(magrittr)
  require(lubridate)
  require(logging)
  require(XLConnect)
  
  functionName <- "LoadOMSData"
  
  loginfo(paste0(functionName, " - Function Start"), logger = nameReport)
  
  invoiceData <- data.frame(pickupDate = character(),
                            trackingNumber = character(),
                            type = character(),
                            origin = character(),
                            dest = character(),
                            pcs = numeric(),
                            weight = numeric(),
                            courierCharges = numeric(),
                            handlingFee = numeric(),
                            fuelSurcharge = numeric(),
                            CODFee = numeric(),
                            lineHaulFee = numeric(),
                            adminFee = numeric(),
                            ELC = numeric(),
                            customFee = numeric(),
                            ODACharges = numeric(),
                            freeTradeZoneFee = numeric(),
                            minimumCNCharges = numeric(),
                            discount = numeric(),
                            promotionDiscount = numeric(),
                            GST = numeric(),
                            total = numeric(),
                            GLCode = character())
  
  filesCount <- sum(grepl("\\.(xls|xlsx)",list.files(invoicePath))) -
    sum(grepl("(^\\~\\$)", list.files(invoicePath)))
  pb <- txtProgressBar(min=0,max=filesCount, style = 3)
  iProgress <- 0
  setTxtProgressBar(pb, iProgress)
  
  for (file in list.files(invoicePath)){
    if(file_ext(file) %in% c("xls", "xlsx") & !grepl("(^\\~\\$)", file)) {
      tryCatch({
        
        wb <- loadWorkbook(file.path(invoicePath,file))
        currentFileData <- readWorksheet(wb, 1, header = TRUE,
                                         colTypes = c("character", "character", "character",
                                                      "character", "character", "numeric",
                                                      "numeric", "numeric", "numeric",
                                                      "numeric", "numeric", "numeric",
                                                      "numeric", "numeric", "numeric",
                                                      "numeric", "numeric", "numeric",
                                                      "numeric", "numeric", "numeric",
                                                      "numeric", "character"))
        names(currentFileData) <- c("pickupDate", "trackingNumber", "type",
                                    "origin", "dest", "pcs",
                                    "weight", "courierCharges", "handlingFee",
                                    "fuelSurcharge", "CODFee", "lineHaulFee",
                                    "adminFee", "ELC", "customFee",
                                    "ODACharges", "freeTradeZoneFee", "minimumCNCharges",
                                    "discount", "promotionDiscount", "GST",
                                    "total", "GLCode")
        
        invoiceData <- rbind_list(invoiceData,currentFileData)
      
      }, warning = function(war) {
        logwarn(paste(functionName, file, war, sep = " - "), logger = nameReport)
      }, error = function(err) {
        logerror(paste(functionName, file, err, sep = " - "), logger = consoleLog)
      })
      
      iProgress <- iProgress + 1
      wb <- NULL
      xlcFreeMemory()
      gc()
      setTxtProgressBar(pb, iProgress)
    }
  }
  
  cat("\r\n")
  
  loginfo(paste0(functionName, " - Function End"), logger = nameReport)
  
  invoiceData
}