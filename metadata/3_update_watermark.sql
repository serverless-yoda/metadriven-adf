CREATE PROCEDURE sp_UpdateWatermarkAndLog
    @TableName VARCHAR(100),
    @RunID UNIQUEIDENTIFIER,
    @NewWatermark DATETIME,
    @RowsRead INT,
    @RowsWritten INT,
    @Status VARCHAR(20),
    @ErrorMessage VARCHAR(MAX) = NULL
AS
BEGIN
    -- Update the state in ControlTable
    UPDATE ControlTable
    SET LastWatermarkValue = @NewWatermark,
        LastRunStatus = @Status,
        FailureCount = CASE WHEN @Status = 'Failed' THEN FailureCount + 1 ELSE 0 END,
        IsActive = CASE WHEN FailureCount >= 3 THEN 0 ELSE IsActive END -- Circuit Breaker
    WHERE TableName = @TableName;

    -- Finalize the Audit Log entry
    UPDATE AuditLog
    SET EndTime = GETDATE(),
        Status = @Status,
        RowsRead = @RowsRead,
        RowsWritten = @RowsWritten,
        ErrorMessage = @ErrorMessage
    WHERE RunID = @RunID AND TableName = @TableName;
END;