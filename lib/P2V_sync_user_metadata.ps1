#-----------------------------------------
#  P2V_sync_user_metadata
#-----------------------------------------

#-------------------------------------------------

#  input:  x-key
#  1   get user AD-profile
#  2   select tenant(s) to sync
#  3   get P2V_user profile
#  4   select specific settings (deactivate, locked,other         
#  3   show difference AD-> to_be and as_is profile per tenant
#  4   propose                                                                               

#  5   select changes to apply
#  6   update user in P2v tenant

#=================================================================
# Functions
#=================================================================
#-----------------------------------------------------------------
Function P2V_sync_user_metadata
{ # funtion to select tenant via GUI  -> returns list (1..n  tenants)
  # returns array  $selected_tenants[tenantname]=@{
  #        system         = from Csv $tenantfile
  #        ServerURL      = from Csv $tenantfile
  #        tenant         = from Csv $tenantfile
  #        resource       = from Csv $tenantfile
  #        name           = from Csv $tenantfile
  #        API            = from Csv $tenantfile
  #        ADgroup        = from Csv $tenantfile
  #        base64AuthInfo : calculated string  
  #}
  param (
         [bool] $multiple=$true, 
	     [bool] $all=$false
	 )


Function 
{
	
	
	
}