/* 
This script creates tables in the silver schema, dropping the existing tables if they already exists
*/
drop table if exists silver.crm_cust_info;
create table silver.crm_cust_info(
	cst_id INTEGER,
	cst_key VARCHAR, 
	cst_firstname VARCHAR,
	cst_lastname VARCHAR, 
	cst_material_status VARCHAR, 
	cst_gndr VARCHAR, 
	cst_create_date DATE,
  dwh_create_date DATE DEFAULT NOW()
); 

drop table if exists silver.crm_prd_info;
create table silver.crm_prd_info(
	prd_id INT, 
	prd_key VARCHAR, 
	prd_nm VARCHAR, 
	prd_cost INT, 
	prd_line VARCHAR, 
	prd_start_dt DATE, 
	prd_end_dt DATE,
    dwh_create_date DATE DEFAULT NOW()

);

drop table if exists silver.crm_sales_details;
create table silver.crm_sales_details(
	sls_ord_num VARCHAR, 
	sls_prd_key VARCHAR, 
	sls_cust_id INT, 
	sls_order_dt VARCHAR, 
	sls_ship_dt VARCHAR,
	sls_due_dt VARCHAR, 
	sls_sales INT, 
	sls_quantity INT, 
	sls_price INT,
    dwh_create_date DATE DEFAULT NOW()

);

drop table if exists silver.erp_cust_az12;
create table silver.erp_cust_az12(
	cid VARCHAR, 
	bdate DATE, 
	gen VARCHAR,
    dwh_create_date DATE DEFAULT NOW()

);

drop table if exists silver.erp_loc_a101;
create table silver.erp_loc_a101(
	cid VARCHAR, 
	cntry VARCHAR,
    dwh_create_date DATE DEFAULT NOW()

);

drop table if exists silver.erp_px_cat_g1v2;
create table silver.erp_px_cat_g1v2(
	id VARCHAR, 
	cat VARCHAR, 
	subcat VARCHAR, 
	maintenance VARCHAR,
    dwh_create_date DATE DEFAULT NOW()

);

