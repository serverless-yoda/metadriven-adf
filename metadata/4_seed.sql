-- 1. Reset the Control Table
TRUNCATE TABLE ControlTable;

-- 2. Seed all SalesLT Tables
INSERT INTO ControlTable 
(
    SourceSchema, TableName, SourceType, LoadingPattern, Priority, 
    WatermarkColumn, PrimaryKey, SourcePath, TargetPath, SilverPath, 
    GoldPath, LastWatermarkValue
)
VALUES 
-- CONFIGURATION & REFERENCE (Full Load: Small, static tables)
('SalesLT', 'ProductModel', 'SQL', 'FullLoad', 1, NULL, 'ProductModelID', 'AdventureWorksLT', 'bronze/saleslt/productmodel', 'silver/saleslt/productmodel', 'gold/dim_product', NULL),
('SalesLT', 'ProductCategory', 'SQL', 'FullLoad', 1, NULL, 'ProductCategoryID', 'AdventureWorksLT', 'bronze/saleslt/productcategory', 'silver/saleslt/productcategory', 'gold/dim_product', NULL),
('SalesLT', 'ProductDescription', 'SQL', 'FullLoad', 2, NULL, 'ProductDescriptionID', 'AdventureWorksLT', 'bronze/saleslt/productdescription', 'silver/saleslt/productdescription', 'gold/dim_product', NULL),
('SalesLT', 'ProductModelProductDescription', 'SQL', 'FullLoad', 2, NULL, 'ProductModelID', 'AdventureWorksLT', 'bronze/saleslt/modeldescription', 'silver/saleslt/modeldescription', 'gold/dim_product', NULL),

-- MASTER DATA (Merge: Tables that update frequently like Customers and Products)
('SalesLT', 'Customer', 'SQL', 'Merge', 3, 'ModifiedDate', 'CustomerID', 'AdventureWorksLT', 'bronze/saleslt/customer', 'silver/saleslt/customer', 'gold/dim_customer', NULL),
('SalesLT', 'Product', 'SQL', 'Merge', 3, 'ModifiedDate', 'ProductID', 'AdventureWorksLT', 'bronze/saleslt/product', 'silver/saleslt/product', 'gold/dim_product', NULL),
('SalesLT', 'Address', 'SQL', 'Merge', 4, 'ModifiedDate', 'AddressID', 'AdventureWorksLT', 'bronze/saleslt/address', 'silver/saleslt/address', 'gold/dim_address', NULL),
('SalesLT', 'CustomerAddress', 'SQL', 'Merge', 4, 'ModifiedDate', 'CustomerID', 'AdventureWorksLT', 'bronze/saleslt/customeraddress', 'silver/saleslt/customeraddress', 'gold/dim_customer', NULL),

-- TRANSACTIONAL DATA (Incremental: High volume, time-stamped tables)
-- First load will be Historical (since Watermark is NULL), then it pivots to Append
('SalesLT', 'SalesOrderHeader', 'SQL', 'Incremental', 5, 'ModifiedDate', 'SalesOrderID', 'AdventureWorksLT', 'bronze/saleslt/salesorderheader', 'silver/saleslt/salesorderheader', 'gold/fact_sales', NULL),
('SalesLT', 'SalesOrderDetail', 'SQL', 'Incremental', 6, 'ModifiedDate', 'SalesOrderDetailID', 'AdventureWorksLT', 'bronze/saleslt/salesorderdetail', 'silver/saleslt/salesorderdetail', 'gold/fact_sales', NULL);