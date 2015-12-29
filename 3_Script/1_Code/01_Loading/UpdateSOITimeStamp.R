UpdateSOITimeStamp <- function(currentSOITimeStamp, upToDate = Sys.Date(), 
                               server, username, password) {
  suppressMessages({
    require(dplyr)
    require(tools)
    require(magrittr)
    require(methods)
    require(logging)
    require(data.table)
  })
  
  functionName <- "UpdateSOITimeStamp"
  loginfo(paste("Function", functionName, "started"), logger = reportName)
  
  output <- tryCatch({
    
    source("3_Script/1_Code/01_Loading/ExtractSOIHistory.R")
    
    hasHistoryData = TRUE
    upToDate <- as.Date(upToDate, format("%Y-%m-%d"))
    
    if (is.null(currentSOITimeStamp)) {
      hasHistoryData = FALSE
      curentLastDate = upToDate - 40
    } else {
      curentLastDate <- max(currentSOITimeStamp$rts, currentSOITimeStamp$shipped,
                            currentSOITimeStamp$cancelled, currentSOITimeStamp$delivered,
                            na.rm = TRUE)
    }
    
    soiHisAdd <- ExtractSOIHistory(server = server, username = username, 
                                   password = password,
                                   dateBegin = curentLastDate, dateEnd = upToDate,
                                   batchSize = 25000)
    assign(paste0("soiHisAdd_",curentLastDate,"_",upToDate), soiHisAdd)
    save(paste0("soiHisAdd_",curentLastDate,"_",upToDate),
         file = file.path("3_Script/3_RData", 
                          paste0("soiHisAdd_",curentLastDate,"_",upToDate,".RData")))
    
    soiHisAddWide <- soiHisAdd %>%
      arrange(fk_sales_order_item, desc(created_at)) %>%
      mutate(uniqueKey = paste0(fk_sales_order_item, fk_sales_order_item_status)) %>%
      filter(!duplicated(uniqueKey)) %>%
      select(fk_sales_order_item, fk_sales_order_item_status, created_at) %>%
      spread(fk_sales_order_item_status, created_at)
    soiHisAddWide <- data.table(soiHisAddWide)
    for (iStatus in c('50', '76', '5', '9', '27')) {
      if (!(iStatus %in% names(soiHisAddWide))) {
        soiHisAddWide[, (iStatus) := as.POSIXct(NA)]
      }
    }
    soiHisAddWide <- tbl_df(soiHisAddWide)
    
    soiHisAddWide %<>%
      select(fk_sales_order_item, 
             rts_wh = `50`,
             rts_ds = `76`,
             shipped =`5`,
             cancelled = `9`,
             delivered = `27`) %>%
      mutate(rts = ifelse(is.na(rts_wh), rts_ds, rts_wh)) %>%
      select(-c(rts_wh, rts_ds))
    
    if (hasHistoryData) {
      newSOITimeStamp <- full_join(currentSOITimeStamp, soiHisAddWide,
                                   by = "fk_sales_order_item") %>%
        mutate(rts = ifelse(is.na(rts.y), rts.x, rts.y),
               shipped = ifelse(is.na(shipped.y), shipped.x, shipped.y),
               cancelled = ifelse(is.na(cancelled.y), cancelled.x, cancelled.y),
               delivered = ifelse(is.na(delivered.y), delivered.x, delivered.y)) %>%
        select(fk_sales_order_item, rts, shipped, cancelled, delivered)
    } else {
      newSOITimeStamp <- soiHisAddWide
    }
    
    for (iWarn in warnings()){
      logwarn(paste(functionName, iWarn), logger = reportName)
    }
    
    newSOITimeStamp
    
  }, error = function(err) {
    logerror(paste(functionName, err, sep = " - "), logger = consoleLog)
  }, finally = {
    loginfo(paste(functionName, "ended"), logger = reportName)
  })
  
  output
}
