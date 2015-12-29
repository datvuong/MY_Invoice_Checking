ExtractSOIData <- function(server, username, password, dateBegin, dateEnd,
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
    
    conn <- dbConnect(MySQL(), username = user,
                      password = password, host = server, port = 3306,
                      client.flag = 0)
    
    rowCountQuery <-
      paste0("SELECT
             COUNT(*)
             FROM 
  oms_live.ims_sales_order_item soi 
             INNER JOIN bob_live.catalog_simple bobsku ON bobsku.sku = soi.sku 
             INNER JOIN bob_live.catalog_config skuConfig ON bobsku.fk_catalog_config = skuConfig.id_catalog_config 
             INNER JOIN oms_live.ims_sales_order so ON soi.fk_sales_order = so.id_sales_order 
             INNER JOIN oms_live.ims_sales_order_item_status itemStatus ON soi.fk_sales_order_item_status = itemStatus.id_sales_order_item_status 
             INNER JOIN oms_live.oms_package_item pkgItem ON soi.id_sales_order_item = pkgItem.fk_sales_order_item 
             INNER JOIN oms_live.oms_package pkg ON pkgItem.fk_package = pkg.id_package 
             INNER JOIN oms_live.oms_package_dispatching pkgDispatch ON pkg.id_package = pkgDispatch.fk_package 
             INNER JOIN oms_live.oms_shipment_provider deliveryCompany ON pkgDispatch.fk_shipment_provider = deliveryCompany.id_shipment_provider 
             LEFT JOIN screport.sales_order_item scsoi ON soi.id_sales_order_item = scsoi.src_id 
             LEFT JOIN screport.seller seller ON scsoi.fk_seller = seller.id_seller 
             WHERE 
             (
             pkgDispatch.created_at between '", dateBegin, "' and '", dateEnd,"'
             )")
    
    rs <- dbSendQuery(conn, rowCountQuery)
    rowCount <- dbFetch(rs, n=-1)
    rowCount <- rowCount[1,1]
    
    sellerQuery <- 
      paste0("SELECT
  pkgDispatch.id_package_dispatching,
  pkgDispatch.created_at tracking_created_at,
  so.order_nr, 
  soi.id_sales_order_item, 
  soi.bob_id_sales_order_item, 
  scsoi.id_sales_order_item SC_SOI_ID, 
  if(
    soi.fk_marketplace_merchant is null, 
    'Retail', 'MP'
  ) business_unit, 
  so.payment_method, 
  soi.sku,
  soi.name as product_name,
  soi.unit_price, 
  soi.paid_price, 
  soi.shipping_fee, 
  soi.shipping_surcharge, 
  itemStatus.name Item_Status, 
  pkgDispatch.tracking_number, 
  pkg.package_number, 
  deliveryCompany.shipment_provider_name, 
  seller.short_code 'Seller_Code', 
  seller.tax_class, 
  skuConfig.package_length, 
  skuConfig.package_width, 
  skuConfig.package_height, 
  skuConfig.package_weight 
FROM 
  oms_live.ims_sales_order_item soi 
  INNER JOIN bob_live.catalog_simple bobsku ON bobsku.sku = soi.sku 
  INNER JOIN bob_live.catalog_config skuConfig ON bobsku.fk_catalog_config = skuConfig.id_catalog_config 
  INNER JOIN oms_live.ims_sales_order so ON soi.fk_sales_order = so.id_sales_order 
  INNER JOIN oms_live.ims_sales_order_item_status itemStatus ON soi.fk_sales_order_item_status = itemStatus.id_sales_order_item_status 
  INNER JOIN oms_live.oms_package_item pkgItem ON soi.id_sales_order_item = pkgItem.fk_sales_order_item 
  INNER JOIN oms_live.oms_package pkg ON pkgItem.fk_package = pkg.id_package 
  INNER JOIN oms_live.oms_package_dispatching pkgDispatch ON pkg.id_package = pkgDispatch.fk_package 
  INNER JOIN oms_live.oms_shipment_provider deliveryCompany ON pkgDispatch.fk_shipment_provider = deliveryCompany.id_shipment_provider 
  LEFT JOIN screport.sales_order_item scsoi ON soi.id_sales_order_item = scsoi.src_id 
  LEFT JOIN screport.seller seller ON scsoi.fk_seller = seller.id_seller 
WHERE 
  (
    pkgDispatch.created_at between '", dateBegin, "' and '", dateEnd,"'
  )")
    
    print(rowCount)
    rs <- dbSendQuery(conn, sellerQuery)
    pb <- txtProgressBar(min=0, max=rowCount, style = 3)
    iProgress <- 0
    setTxtProgressBar(pb, iProgress)
    
    soiHis <- dbFetch(rs, n = batchSize)
    iProgress <- nrow(soiHis)
    setTxtProgressBar(pb, iProgress)
    while (nrow(soiHis) < rowCount) {
      temp <- dbFetch(rs, n = batchSize)
      soiHis <- rbind(soiHis,temp)
      
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






