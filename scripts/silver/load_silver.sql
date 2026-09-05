/* 
These codes clean and normalize the data from bronze layer and insert it into their 
respective silver layers 
*/
--- inserting data into the silver.crm_cust_info table ----
INSERT INTO silver.crm_cust_info(
	cst_id, 
	cst_key,
	cst_firstname, 
	cst_lastname, 
	cst_material_status, 
	cst_gndr, 
	cst_create_date
)
select 
cst_id, 
cst_key,
TRIM(cst_firstname) AS cst_firstname, 
TRIM(cst_lastname) AS cst_lastname, 

CASE WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
	WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
	ELSE 'n/a'
END cst_material_status,

CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	ELSE 'n/a'
END cst_gndr, 
cst_create_date
FROM (
	SELECT 
	*,
	ROW_NUMBER() OVER (Partition by cst_id order by cst_create_date DESC) as flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
) WHERE flag_last = 1 

select * from silver.crm_cust_info

-- recreating the silver.crm_prd_info table ----
drop table if exists silver.crm_prd_info;
create table silver.crm_prd_info(
	prd_id INT, 
	cat_id VARCHAR, 
	prd_key VARCHAR, 
	prd_nm VARCHAR, 
	prd_cost INT,
	prd_line VARCHAR, 
	prd_start_dt DATE, 
	prd_end_dt DATE, 
	dwh_create_date DATE DEFAULT NOW()
);

-- inserting data into silver.crm_prd_info ---- 
insert into silver.crm_prd_info(
	prd_id, 
	cat_id, 
	prd_key, 
	prd_nm, 
	prd_cost, 
	prd_line, 
	prd_start_dt, 
	prd_end_dt
)

Select 
prd_id, 
REPLACE(SUBSTRING(prd_key,1,5), '-','_') as cat_id, 
SUBSTRING(prd_key,7,LENGTH(prd_key)) AS prd_key,
prd_nm, 
COALESCE(prd_cost,0) AS prd_cost, 
CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
 WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
  WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
   WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
   ELSE 'n/a'
   END as prd_line,
   CAST(prd_start_dt AS DATE) AS prd_start_dt,
CAST(LEAD(prd_start_dt) OVER (Partition by prd_key order by prd_start_dt) -1 AS DATE) AS prd_end_dt_te
From bronze.crm_prd_info

-- recreating the crm_sales_details table --
drop table if exists silver.crm_sales_details;
create table silver.crm_sales_details(
	sls_ord_num VARCHAR, 
	sls_prd_key VARCHAR, 
	sls_cust_id INT, 
	sls_order_dt DATE, 
	sls_ship_dt DATE, 
	sls_due_dt DATE, 
	sls_sales INT, 
	sls_quantity INT, 
	sls_price INT, 
	dwh_create_date DATE DEFAULT NOW()
);

-- inserting into crm_sales_details --
INSERT INTO silver.crm_sales_details(
	sls_ord_num, 
	sls_prd_key, 
	sls_cust_id, 
	sls_order_dt, 
	sls_ship_dt, 
	sls_due_dt, 
	sls_sales, 
	sls_quantity, 
	sls_price 
)
SELECT 
sls_ord_num, 
sls_prd_key,
sls_cust_id, 
CASE WHEN sls_order_dt = '0' OR LENGTH(sls_order_dt) !=8 THEN NULL 
	ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) 
END AS sls_order_dt,
CASE WHEN sls_ship_dt = '0' OR LENGTH(sls_ship_dt) !=8 THEN NULL 
	ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) 
END AS sls_ship_dt,
CASE WHEN sls_due_dt = '0' OR LENGTH(sls_due_dt) !=8 THEN NULL 
	ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) 
END AS sls_due_dt,
CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
	THEN sls_quantity * ABS(sls_price)
ELSE sls_sales
END AS sls_sales,
sls_quantity, 
CASE WHEN sls_price IS NULL OR sls_price <= 0 
	THEN sls_sales / NULLIF (sls_quantity,0)
ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details 

select * from silver.crm_sales_details

-- cleaing and loading data from erp_cust_az12 -- 
INSERT INTO silver.erp_cust_az12 (
cid, 
bdate, 
gen
)
SELECT  
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
	ELSE cid 
END cid, 
CASE WHEN bdate > NOW() THEN NULL 
	ELSE bdate
END AS bdate, 
CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
	WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
	ELSE 'n/a'
END AS gen
FROM bronze.erp_cust_az12 

SELECT * FROM silver.erp_cust_az12

--- Cleaning and Loading data from erp.loc_a101 --- 
INSERT INTO silver.erp_loc_a101(
	cid, 
	cntry
)
SELECT 
REPLACE (cid, '-', '') cid, 
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
	WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	ELSE cntry
END AS 
cntry
FROM bronze.erp_loc_a101;
SELECT * from silver.erp_loc_a101


--- Cleaning and Loading data from erp_px_cat_g1v2 ---
INSERT INTO silver.erp_px_cat_g1v2 
(
	id, 
	cat,
	subcat, 
	maintenance
)
SELECT 
id, 
cat, 
subcat, 
maintenance 
FROM bronze.erp_px_cat_g1v2 
