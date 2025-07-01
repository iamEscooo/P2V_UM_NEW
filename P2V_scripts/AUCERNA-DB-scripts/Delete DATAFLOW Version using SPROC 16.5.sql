
-------Deletes a dataflow version using the VersionDelete stored procedure. 
--------This sproc will only delete a version if it is not used as a source.
--------DO NOT run this script without taking a backup first

IF IS_ROLEMEMBER('dbo') = 0
BEGIN
	RAISERROR ('This script must be run by a user with the dbo role',16,1)
	RETURN;
END 

EXEC	[DATAFLOW].[VersionDelete]
		@VersionName = N'Atlantis_Res2015YE 15.2'