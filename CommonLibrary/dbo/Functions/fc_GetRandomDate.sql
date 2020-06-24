

/*********************************************************
Author		: Agunahwan Absin
Create Date	: 22/06/2020
Description	: Function for get random value for date
Example		: SELECT dbo.fc_GetRandomDate('2010-01-01','2020-06-22')
**********************************************************/
CREATE FUNCTION [dbo].[fc_GetRandomDate] (
	@StartDate DATETIME = NULL
	,@EndDate DATETIME = NULL
	)
RETURNS DATETIME
AS
BEGIN
	DECLARE @Result DATETIME
		,@StartTotalDay INT
		,@EndTotalDay INT

	-- Set default value @StartDate
	IF (@StartDate IS NULL)
	BEGIN
		SET @StartDate = CAST(0 AS DATETIME)
	END

	-- Set default value @EndDate
	IF (@EndDate IS NULL)
	BEGIN
		SET @EndDate = GETDATE()
	END

	SET @StartTotalDay = DATEDIFF(DAY, 0, @StartDate)
	SET @EndTotalDay = DATEDIFF(DAY, 0, @EndDate) - @StartTotalDay

	-- Generate random date
	SET @Result = DATEADD(day, (
				ABS(CHECKSUM((
							SELECT new_id
							FROM getNewID
							))) % @EndTotalDay
				), @StartTotalDay)

	RETURN @Result
END

