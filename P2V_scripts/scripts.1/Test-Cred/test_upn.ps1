$user_list=@('BogdanMarius.Dinu@petrom.com','BogdanMarius.Dinu@omv.com','martin.kufner@omv.com')

foreach ($login in $user_list)
{
   $login
   $mail1=$login.substring(0,$login.IndexOf("@"))
   
   $mail1
   
   $u_res=Get-ADUser -Filter { (UserPrincipalName -like $login)} -properties * |
		    select      Name, 
		        Givenname, 
				surname,
				SamAccountName,
				UserPrincipalName, 
				EmailAddress, 
				Department,
				distinguishedName,
				lastlogon,
				lastLogonTimestamp,
				accountExpires,
				description,
                proxyAddresses,
                targetaddress,
			    Enabled				

  $u_res

   # |%   {if ($_ -contains $mail1) { write-output $_} }
  Foreach ($u in $u_res.proxyAddresses)
  {
     if ( $u.Contains("smtp") -or $u.Contains("SMTP"))
     {
       $u #.substring(5)
       }
       }

  "------------------------------------------------------"
  pause
}