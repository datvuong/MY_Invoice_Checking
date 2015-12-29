ExtractSOIHistory <- function(server, username, password, dateBegin, dateEnd,
                              batchSize = 10000) {
  suppressMessages({
    require(dplyr)
    require(tools)
    require(magrittr)
    require(methods)
    require(RMySQL)
    require(logging)
  })
  
  functionName <- "ExExtractsoiHis"
  loginfo(paste("Function", functionName, "started"), logger = reportName)
  
  output <- tryCatch({
    
    conn <- dbConnect(MySQL(), username = username,
                      password = password, host = server, port = 3306,
                      client.flag = 0)
    
    rowCountQuery <-
      paste0("SELECT
      	        COUNT(*)
              FROM oms_live.ims_sales_order_item_status_history soihis
              WHERE soihis.created_at BETWEEN '", dateBegin,"' AND '", dateEnd,"'")
    
    rs <- dbSendQuery(conn, rowCountQuery)
    rowCount <- dbFetch(rs, n=-1)
    rowCount <- rowCount[1,1]
    
    dataQuery <- 
      paste0("SELECT
      	        soihis.*
              FROM oms_live.ims_sales_order_item_status_history soihis
              WHERE soihis.created_at BETWEEN '", dateBegin,"' AND '", dateEnd,"'")
    
    
    print(rowCount)
    rs <- dbSendQuery(conn, dataQuery)
    pb <- txtProgressBar(min=0, max=rowCount, style = 3)
    iProgress <- 0
    setTxtProgressBar(pb, iProgress)
    
    
    soiHis <- dbFetch(rs, n = batchSize)
    iProgress <- nrow(soiHis)
    setTxtProgressBar(pb, iProgress)
    
    for (i in 1:round(((rowCount / batchSize) + 10), digits = 0)) {
      temp <- dbFetch(rs, n = batchSize)
      soiHis <- rbind(soiHis,temp)
      
      dbHasCompleted(rs)
      
      iProgress <- nrow(soiHis)
      setTxtProgressBar(pb, iProgress)
    }
    
    
    cat("\r\n")
    print(nrow(soiHis))
    dbClearResult(rs)
    rm(temp)
    
    for (iWarn in warnings()){
      logwarn(paste(functionName, iWarn), logger = reportName)
    }
    assign("last.warning", NULL, envir = baseenv())
    soiHis
    
  }, error = function(err) {
    logerror(paste(functionName, err, sep = " - "), logger = consoleLog)
  }, finally = {
    dbDisconnect(conn)
    loginfo(paste(functionName, "ended"), logger = reportName)
  })
  
  output
}






