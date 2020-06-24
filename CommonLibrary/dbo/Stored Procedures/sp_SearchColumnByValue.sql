
/*********************************************************
Author		: Agunahwan Absin
Create Date	: 24/06/2020
Description	: Stored Procedure for get column in table by value of row
Example		: EXEC dbo.sp_SearchColumnByValue 'Akademik','Agun'
**********************************************************/
CREATE PROCEDURE [dbo].[sp_SearchColumnByValue] @DatabaseName VARCHAR(128) = ''
	,@Value VARCHAR(MAX) = ''
	,@TableName VARCHAR(128) = NULL
	,@TableSchemaName VARCHAR(128) = 'dbo'	
AS
BEGIN
	DECLARE @CountTable INT = 1
		,@IncTable INT = 1
		,@Query VARCHAR(MAX) = ''

	-- Validation if @DatabaseName is empty
	IF (@DatabaseName = '')
	BEGIN
		RAISERROR (
				15600
				,- 1
				,- 1
				,'Database name must be filled'
				);
	END

	-- Preventive steps for handling error if ##TempResult is exists
	IF OBJECT_ID('tempdb..##TempResult') IS NOT NULL
	BEGIN
		DROP TABLE ##TempResult
	END

	-- Create table ##TempResult with empty data
	SET @Query = 'SELECT t.TABLE_NAME
				,COLUMN_NAME
				,CONVERT(INT, 1) AS TOTAL_DATA
			INTO ##TempResult
			FROM ' + @DatabaseName + '.INFORMATION_SCHEMA.TABLES t
			JOIN ' + @DatabaseName + '.INFORMATION_SCHEMA.COLUMNS c ON t.TABLE_NAME = c.TABLE_NAME
			WHERE 1 = 2'

	EXEC (@Query)

	-- Preventive steps for handling error if ##TempTables is exists
	IF OBJECT_ID('tempdb..##TempTables') IS NOT NULL
	BEGIN
		DROP TABLE ##TempTables
	END

	-- Create table ##TempTables with empty data
	SET @Query = 'SELECT IDENTITY(INT, 1, 1) AS ID
				,TABLE_NAME
			INTO ##TempTables
			FROM ' + @DatabaseName + '.INFORMATION_SCHEMA.TABLES
			WHERE TABLE_TYPE = ''BASE TABLE''
				AND TABLE_NAME <> ''sysdiagrams''
				AND TABLE_SCHEMA = ''' + @TableSchemaName + ''''

	IF (@TableName IS NOT NULL)
	BEGIN
		SET @Query = @Query + ' AND TABLE_NAME = ''' + @TableName + ''''
	END

	EXEC (@Query)

	-- Set delimiter loop
	SELECT @IncTable = 1
		,@CountTable = Count(1)
	FROM ##TempTables

	-- Looping for executing all tables to search table name
	WHILE (@IncTable <= @CountTable)
	BEGIN
		DECLARE @CountColumn INT
			,@IncColumn INT

		-- Get table name for searching in this table & for retrieving all columns in that table
		SELECT @TableName = TABLE_NAME
		FROM ##TempTables
		WHERE ID = @IncTable

		-- Preventive steps for handling error if ##TempColumns is exists
		IF OBJECT_ID('tempdb..##TempColumns') IS NOT NULL
		BEGIN
			DROP TABLE ##TempColumns
		END

		-- Generate query for getting all columns in the table
		SET @Query = 'SELECT IDENTITY(INT, 1, 1) AS ID
					,c.name AS COLUMN_NAME
					,type_name(c.user_type_id) AS DATA_TYPE
				INTO ##TempColumns
				FROM ' + @DatabaseName + '.INFORMATION_SCHEMA.TABLES it
				JOIN ' + @DatabaseName + '.sys.tables t ON it.TABLE_NAME = t.NAME
				JOIN ' + @DatabaseName + '.sys.columns c ON t.object_id = c.object_id
				WHERE it.TABLE_SCHEMA = ''' + @TableSchemaName + ''' 
					AND type_name(c.user_type_id) <> ''TEXT'' 
					AND it.TABLE_NAME = ''' + @TableName + '''
					AND c.max_length >= ' + CONVERT(VARCHAR, LEN(@Value))

		EXEC (@Query)

		-- Set delimiter loop
		SELECT @IncColumn = 1
			,@CountColumn = Count(1)
		FROM ##TempColumns

		-- Looping for executing all columns to search column name
		WHILE (@IncColumn <= @CountColumn)
		BEGIN
			DECLARE @ColumnName VARCHAR(128)
				,@DataType VARCHAR(8000)

			-- Get column name & the data type for searching in the column
			SELECT @ColumnName = COLUMN_NAME
				,@DataType = DATA_TYPE
			FROM ##TempColumns
			WHERE ID = @IncColumn

			-- Generate query for checking if the value exists in that table & column
			SET @Query = 'INSERT INTO ##TempResult (TABLE_NAME, COLUMN_NAME, TOTAL_DATA) 
					SELECT ''' + @TableName + ''' AS TABLE_NAME
						,''' + @ColumnName + ''' AS COLUMN_NAME
						,COUNT(1) AS TOTAL_DATA
					FROM ' + @DatabaseName + '.' + @TableSchemaName + '.' + @TableName

			-- If the data type is varchar, nvarchar, xml, or nchar then use try_cast for comparing value
			IF (
					@DataType IN (
						'VARCHAR'
						,'NVARCHAR'
						,'XML'
						,'NCHAR'
						,'CHAR'
						,'TEXT'
						)
					)
			BEGIN
				SET @Query = @Query + ' WHERE ' + @ColumnName + ' = TRY_CAST(''' + @Value + ''' AS ' + @DataType + ') '
			END
			ELSE IF (@DataType IN ('UNIQUEIDENTIFIER')) -- If the data type is UNIQUEIDENTIFIER then use try_convert for comparing value
			BEGIN
				SET @Query = @Query + ' WHERE ' + @ColumnName + ' = TRY_CONVERT(' + @DataType + ',''' + @Value + ''') '
			END
			ELSE -- and use try_parse for else
			BEGIN
				SET @Query = @Query + ' WHERE ' + @ColumnName + ' = TRY_PARSE(''' + @Value + ''' AS ' + @DataType + ') '
			END

			SET @Query = @Query + 'GROUP BY ' + @ColumnName

			EXEC (@Query)

			SET @IncColumn = @IncColumn + 1
		END

		DROP TABLE ##TempColumns

		SET @IncTable = @IncTable + 1
	END

	-- Show all data that have the value
	SELECT *
	FROM ##TempResult
	WHERE TOTAL_DATA > 0

	DROP TABLE ##TempTables

	DROP TABLE ##TempResult
END

