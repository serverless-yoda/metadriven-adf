-- Create the Audit & Observability Log
CREATE TABLE AuditLog (
    LogID INT PRIMARY KEY IDENTITY(1,1),
    TableName VARCHAR(100),
    RunID UNIQUEIDENTIFIER,                 -- ADF System Variable: @pipeline().RunId
    StartTime DATETIME DEFAULT GETDATE(),
    EndTime DATETIME NULL,
    Status VARCHAR(20),                     -- Success, Failed, In-Progress
    RowsRead INT DEFAULT 0,
    RowsWritten INT DEFAULT 0,
    ErrorMessage VARCHAR(MAX) NULL
);