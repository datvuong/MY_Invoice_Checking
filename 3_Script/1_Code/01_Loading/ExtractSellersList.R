ExtractSellerList <- function(venture) {
  suppressMessages({
    require(dplyr)
    require(tools)
    require(magrittr)
    require(methods)
    require(RMySQL)
    require(logging)
  })
  
  functionName <- "ExExtractSellerList"
  loginfo(paste("Function", functionName, "started"), logger = reportName)
  
  output <- tryCatch({
    
    ip <- c("10.34.25.35", "10.50.50.180",
            "10.50.50.49", "10.50.50.160",
            "10.50.50.158", "10.50.50.58")
    venture <- c("ID","MY","PH","SG","TH","VN")
    conf <- data.frame(venture,ip)
    
    args <- commandArgs(trailingOnly = TRUE)
    country <- as.character(args[1])
    country <- "ID"
    
    user <- "sinh_all_bi"
    password <- "u5DHjeQrS8dCHMey"
    
    adb_ip <- as.character(conf$ip[conf$venture == country])
    
    conn <- dbConnect(MySQL(), dbname = "oms_live", username = user,
                      password = password, host = adb_ip, port = 3306,
                      client.flag = 0)
    
    rowCountQuery <-
      "SELECT
          COUNT(*)
       FROM screport.seller seller"
    
    rs <- dbSendQuery(conn, rowCountQuery)
    rowCount <- dbFetch(rs, n=-1)
    rowCount <- rowCount[1,1]
    
    sellerQuery <- 
      ("SELECT
        	 seller.id_seller
        	,seller.name
        	,seller.short_code
        	,seller.src_id 'oms_seller_id'
        	,seller.tax_class
        FROM screport.seller seller")
    
    rs <- dbSendQuery(conn, sellerQuery)
    batchSize <- 1000
    
    pb <- txtProgressBar(min=0, max=rowCount, style = 3)
    iProgress <- 0
    setTxtProgressBar(pb, iProgress)
    
    
    sellerList <- dbFetch(rs, n = batchSize)
    iProgress <- nrow(sellerList)
    setTxtProgressBar(pb, iProgress)
    
    for (i in 1:round(((rowCount / batchSize) + 10), digits = 0)) {
      temp <- dbFetch(rs, n = batchSize)
      sellerList <- rbind(sellerList,temp)
      
      dbHasCompleted(rs)
      
      iProgress <- nrow(sellerList)
      setTxtProgressBar(pb, iProgress)
    }
    
    
    dbClearResult(rs)
    dbDisconnect(conn)
    rm(temp)
    
    for (iWarn in warnings()){
      logwarn(paste(functionName, iWarn), logger = reportName)
    }
    assign("last.warning", NULL, envir = baseenv())
    sellerList
    
  }, error = function(err) {
    logerror(paste(functionName, err, sep = " - "), logger = consoleLog)
  }, finally = {
    loginfo(paste(functionName, "ended"), logger = reportName)
  })
  
  output
}






