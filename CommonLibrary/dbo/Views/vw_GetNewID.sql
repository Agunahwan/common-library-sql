

/*********************************************************
Author		: Agunahwan Absin
Create Date	: 22/06/2020
Description	: View for get New ID
Example		: SELECT * FROM dbo.vw_GetNewID
**********************************************************/
CREATE VIEW [dbo].[vw_GetNewID]
AS
SELECT NEWID() AS new_id

