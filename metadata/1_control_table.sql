-- Create the main Control Table
CREATE TABLE ControlTable (
    TableID INT PRIMARY KEY IDENTITY(1,1),
    SourceSchema VARCHAR(50) NOT NULL,      -- e.g., SalesLT
    TableName VARCHAR(100) NOT NULL,        -- e.g., Product
    SourceType VARCHAR(20) NOT NULL,        -- SQL, JSON, Binary
    LoadingPattern VARCHAR(20) NOT NULL,    -- FullLoad, Incremental, Merge, Historical
    Priority INT DEFAULT 10,                -- Lower number = Higher priority
    MaxConcurrency INT DEFAULT 5,           -- Limit parallel loads for FinOps
    WatermarkColumn VARCHAR(50) NULL,       -- e.g., ModifiedDate
    PrimaryKey VARCHAR(50) NULL,            -- Required for Merge/Upsert logic
    SourcePath VARCHAR(255) NOT NULL,       -- Dataset source parameter
    TargetPath VARCHAR(255) NOT NULL,       -- ADLS folder structure
    IsActive BIT DEFAULT 1,                 -- Global Kill Switch per table
    LastWatermarkValue DATETIME NULL,       -- State management for delta loads
    FailureCount INT DEFAULT 0,             -- Circuit breaker: deactivate if > threshold
    LastRunStatus VARCHAR(20) NULL          -- Quick view of health
);


ALTER TABLE ControlTable ADD 
    SilverPath VARCHAR(255) NULL,       -- e.g., 'silver/saleslt/customer'
    GoldPath VARCHAR(255) NULL,         -- e.g., 'gold/fact_sales'
    DeduplicationType VARCHAR(20) NULL; -- e.g., 'Upsert' or 'Overwrite'
