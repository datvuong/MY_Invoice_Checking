LoadInvoiceData <- function(invoicePath) {
suppressMessages({
    require(dplyr)
    require(tools)
    require(magrittr)
    require(methods)
    require(logging)
  })
  
  functionName <- "LoadGDexInvoiceData"
  loginfo(paste("Function", functionName, "started"), logger = reportName)
  
  invoiceData <- tryCatch({
    
    setClass("myDate")
    setAs("character","myDate", function(from) as.POSIXct(substr(gsub('"','',from), 1, 10),
                                                              format="%Y-%m-%d"))
    setClass("myInteger")
    setAs("character","myInteger", function(from) as.integer(gsub('"','',from)))
    setClass("myNumeric")
    setAs("character","myNumeric", function(from) as.numeric(gsub('"','',from)))
    setClass("myTrackingNumber")
    setAs("character","myTrackingNumber", function(from) toupper((gsub('^0+','',trimws(from)))))
    
    
    invoiceData <- data.frame(lineID = character(),
                              deliveryCompany = character(),
                              pacagePickupDate = as.POSIXct(character()),
                              pacagePODDate = as.POSIXct(character()),
                              invoiceNumber = character(),
                              packageNumber = character(),
                              trackingNumber = character(),
                              trackingNumberRTS = character(),
                              orderNumber = numeric(),
                              packageVolume = numeric(),
                              packageHeight = numeric(),
                              packageWidth = numeric(),
                              packageLength = numeric(),
                              packageWeight = numeric(),
                              packageChargeableWeight = numeric(),
                              carryingFee = numeric(),
                              redeliveryFee = numeric(),
                              rejectionFee = numeric(),
                              CODFee = numeric(),
                              specialAreaFee = numeric(),
                              specialHandlingFee = numeric(),
                              insuranceFee = numeric(),
                              VAT = numeric(),
                              originBranch = character(),
                              destinationBranch = character(),
                              deliveryZoneZipCode = character(),
                              rateType = character())
    
    filesCount <- sum(grepl("\\.(csv)",list.files(invoicePath))) -
      sum(grepl("(^\\~\\$)", list.files(invoicePath)))
    pb <- txtProgressBar(min=0,max=filesCount, style = 3)
    iProgress <- 0
    setTxtProgressBar(pb, iProgress)
    
    setAs("character","myDateTime", function(from) as.POSIXct(gsub('"','',from), format="%Y-%m-%d %H:%M:%S"))
    setClass("myInteger")
    setAs("character","myInteger", function(from) as.integer(gsub('"','',from)))
    setClass("myNumeric")
    setAs("character","myNumeric", function(from) as.numeric(gsub('"','',from)))
    
    for (file in list.files(invoicePath)){
      if(file_ext(file) %in% c("csv") & !grepl("(^\\~\\$)", file)) {
        tryCatch({
          currentFileData <- read.csv(file.path(invoicePath, file),
                                      quote = '"', sep=",", row.names = NULL,
                                      col.names=c("line_id",	"deliveryCompany",	"pacagePickupDate",
                                                  "pacagePODDate",	"invoiceNumber",	"packageNumber",
                                                  "trackingNumber",	"trackingNumberRTS",	"orderNumber",
                                                  "packageVolume",	"packageHeight",	"packageWidth",
                                                  "packageLength",	"packageWeight",	"packageChargeableWeight",
                                                  "carryingFee",	"redeliveryFee",	"rejectionFee",
                                                  "CODFee",	"specialAreaFee",	"specialHandlingFee",
                                                  "insuranceFee",	"VAT",	"originBranch",
                                                  "destinationBranch",	"deliveryZoneZipCode", "rate_type"),
                                      colClasses = c("character", "character", "myDate",
                                                     "myDate", "character", "myTrackingNumber",
                                                     "myTrackingNumber", "myTrackingNumber", "myNumeric",
                                                     "myNumeric", "myNumeric", "myNumeric",
                                                     "myNumeric", "myNumeric", "myNumeric",
                                                     "myNumeric", "myNumeric", "myNumeric",
                                                     "myNumeric","myNumeric", "myNumeric",
                                                     "myNumeric","myNumeric", "character",
                                                     "character", "character", "character"))
          
          currentFileData %<>% mutate(invoiceFile = file)
          
          invoiceData <- rbind_list(invoiceData,currentFileData)
          
        }, warning = function(war) {
          logwarn(paste(functionName, file, war, sep = " - "), logger = reportName)
        }, error = function(err) {
          logerror(paste(functionName, file, err, sep = " - "), logger = consoleLog)
        })
        
        iProgress <- iProgress + 1
        setTxtProgressBar(pb, iProgress)
      }
    }
    
    cat("\r\n")
    
    invoiceData %<>%
      mutate(rowID = row_number())
    
    for (iWarn in warnings()){
      logwarn(paste(functionName, iWarn), logger = reportName)
    }
    
    invoiceData
    
  }, error = function(err) {
    logerror(paste(functionName, err, sep = " - "), logger = consoleLog)
  }, finally = {
    loginfo(paste(functionName, "ended"), logger = reportName)
  })
  
  invoiceData
}