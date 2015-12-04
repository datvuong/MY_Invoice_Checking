SELECT DISTINCT
	 so.order_nr
	,soi.id_sales_order_item
        ,soi.bob_id_sales_order_item
	,scsoi.id_sales_order_item SC_SOI_ID
	,if(soi.fk_marketplace_merchant is null, 
		 'Retail', 'MP') business_unit
	,so.payment_method
	,soi.sku
	,soi.unit_price
	,soi.paid_price
	,soi.shipping_fee
	,soi.shipping_surcharge
	,itemStatus.name Item_Status
	,rts.created_at RTS_Date
	,shipped.created_at Shipped_Date
	,cancelled.created_at Cancelled_Date
	,delivered.created_at Delivered_Date
	,pkgDispatch.tracking_number
	,pkg.package_number
	,deliveryCompany.shipment_provider_name
	,seller.short_code 'Seller_Code'
	,seller.tax_class
	,soaddress.city shipping_city
	,soaddress.customer_address_region_name shipping_region
	,skuConfig.package_length
	,skuConfig.package_width
	,skuConfig.package_height
	,skuConfig.package_weight
FROM oms_live.ims_sales_order_item soi
INNER JOIN bob_live.catalog_simple bobsku ON bobsku.sku = soi.sku
INNER JOIN bob_live.catalog_config skuConfig ON bobsku.fk_catalog_config = skuConfig.id_catalog_config
INNER JOIN oms_live.ims_sales_order so ON soi.fk_sales_order=so.id_sales_order
INNER JOIN oms_live.ims_sales_order_item_status itemStatus ON soi.fk_sales_order_item_status=itemStatus.id_sales_order_item_status
INNER JOIN oms_live.ims_sales_order_item_status_history rts ON soi.id_sales_order_item=rts.fk_sales_order_item AND rts.fk_sales_order_item_status IN (50,76)
INNER JOIN oms_live.oms_package_item pkgItem ON soi.id_sales_order_item=pkgItem.fk_sales_order_item
INNER JOIN oms_live.oms_package pkg ON pkgItem.fk_package=pkg.id_package
INNER JOIN oms_live.oms_package_dispatching pkgDispatch ON pkg.id_package=pkgDispatch.fk_package
INNER JOIN oms_live.oms_shipment_provider deliveryCompany ON pkgDispatch.fk_shipment_provider=deliveryCompany.id_shipment_provider
INNER JOIN oms_live.ims_sales_order_address soaddress ON soaddress.id_sales_order_address=so.fk_sales_order_address_shipping
LEFT JOIN oms_live.ims_sales_order_item_status_history shipped ON soi.id_sales_order_item=shipped.fk_sales_order_item AND shipped.fk_sales_order_item_status=5
LEFT JOIN oms_live.ims_sales_order_item_status_history delivered ON soi.id_sales_order_item=delivered.fk_sales_order_item AND delivered.fk_sales_order_item_status=27
LEFT JOIN oms_live.ims_sales_order_item_status_history cancelled ON soi.id_sales_order_item=cancelled.fk_sales_order_item AND cancelled.fk_sales_order_item_status=9
LEFT JOIN screport.sales_order_item scsoi ON soi.id_sales_order_item=scsoi.src_id
LEFT JOIN screport.seller seller ON scsoi.fk_seller=seller.id_seller
WHERE 
	(rts.created_at between '2015-10-01' and '2015-11-01')