#=======================
#  main user interface
#
#  name:    %(refname)
#  ver:     1.0
#  author:  %(*authorname) / %(*authoremail)
#
#  description:
#
#  by From: 
#=======================
#--
#--

$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
#$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
  $My_Path = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
  } else {
    $My_Path = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
    if (!$My_Path){ $My_Path = "." }
  }
if (!$workdir) {$workdir=$My_Path}
. "$workdir/lib/P2V_include.ps1"

#-- global variable --
$u_list=@()
$mainmenu =@()
##  menu definition

Import-Csv $menu_file | %{ $mainmenu+= $_ }
#$mainmenu.count
#$mainmenu |format-table

#-- start main part
do
{
     cls
	 P2V_header -app $My_name -path $My_path 
	 
     out-host
     #$input = Read-Host "Please make a selection"
     $input = P2V_Show-Menu_GUI -Title "Main Menu - Please make a selection" -menu $mainmenu 
	 #$input
	 #$mainmenu[$input-1]|format-table
	 #pause
     switch ($input)
     {
	       '0' {
                return
               }
			
           'old' {   #"search for x-key"
                 $inp=""
				 $user_list =@()
				 $u_res= @()
                 do 
				 {
				    while (!$inp) {$inp= Read-Host "Please enter search term: (0=exit)"}
					if (!($inp -eq "0"))
					{
						$u_res=Get-ADUser -Filter { (Givenname -like $inp) -or (Surname -like $inp) -or (Name -like $inp)} -properties * |select Name, Givenname, surname,UserPrincipalName, Department, EmailAddress
					
					   If ($u_res) 
					   {
					     $u_sel=$u_res
						 #$u_sel=$u_res |out-gridview -title "search-results for $inp"  -PassThru}
						 $u_sel|% {
						 $user_list += [PSCustomObject]@{
                               logOnId = $_.UserPrincipalName
                               #domain = $_.Domain
                               displayName = "$($_.Surname) $($_.GivenName) ($($_.Name))"
                               description = $_.Department -replace '[,]', ''
                               isDeactivated = $False
                               isAccountLocked = $False
                               useADEmailAddress    = $True
                               authenticationMethod = "SAML2"
                              }			  
						 }
						 
						 $user_list |format-table 
						 
					   }
			     		else    {"$u_res not found in Active Directory"}
						$inp=""
					}
					
				 } until ($inp -eq "0")
				 "`n"
				 $form1 -f "export format"
				 "LogonId,DisplayName,Description,IsDeactivated,IsAccountLocked,EmailAddress,authenticationMethod"
				 $user_list |% {
				#Add-Content $usersFile -Value 
				$_.logOnId + "," + $_.displayName + "," + $_.description + "," + $_.isDeactivated + "," + $_.isAccountLocked + "," + $_.emailAddress + "," + $_.authenticationMethod 
				}
				 pause
			   }
			   
               #"Check individual user(s) in AD"
			   #"Check individual user(s) in P2V"
			   #"check locked users"
			   #"export P2V userlists"
			   #"export P2V auditlogs"
			   #"check all locked users"
			   #"create new user(s)"
			   #"manage user workgroups"
			   #"manage user workgroups - UI"
			   #"calculate Access groups"
			   #"apply user profiles"
			   
           default {  
                cls
				
				& $lib_path$($mainmenu[$input-1].script)
				
				
               }
            
             
     }
	 out-host
} until ($input -eq '0')
$called=$False