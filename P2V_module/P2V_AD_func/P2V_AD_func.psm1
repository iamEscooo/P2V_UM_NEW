#=================================================================
#  P2V_AD_func.psm1
#=================================================================
if (get-module -name "P2V_config") {if ($debug) {(Get-Module -name "*P2V*")|out-gridview -title "modules - loaded" -wait}}
else                               { import-module -name "..\P2V_config.psd1" -verbose }
#if (get-module -name "P2V_include") {if ($debug) {(Get-Module -name "*P2V*")|out-gridview -title "modules - loaded" -wait}}
#else                               { import-module -name "..\P2V_include.psd1" -verbose }
<#
.SYNOPSIS
	different dialog forms for P2V Usermgmt
.DESCRIPTION
	

.PARAMETER menufile <filename>
	
	
.PARAMETER xamldir <directory>
	
	
.PARAMETER fcolor  <colorcode>
	foregroundcolor of menubuttons  
    colorcode = colorname like 'lightblue'  or HEXcode like #003366"

.PARAMETER bcolor  <colorcode>
	backgroundcolor of menubuttons  
    colorcode = colorname like 'lightblue'  or HEXcode like #003366"

.INPUTS
	Description of objects that can be piped to the script.

.OUTPUTS
	Description of objects that are output by the script.

.EXAMPLE
	Example of how to run the script.

.LINK
	Links to further documentation.

.NOTES
  name:   P2V_AD_func.psm1
  ver:    1.0
  author: M.Kufner

#>
#=================================================================
# Variables
#=================================================================

$global:ADgroup_members=@{}     #$ADgroup_members[<Adgroup>] = @{createdate, @(list of xkeys) }
$global:AD_userlist=@{}         #$AD_userlist[<SamAccountName>] = @{profile ..}



#=================================================================
# Functions  
#  for Active Directory
#=================================================================
Function NEW_get_AD_user
{ # load specific AD userprofile
    param (
    	    [string]$xkey=""
     )
	 $u_res=@{}
	 
	 
	 $u_res= Get-ADUser -identity $xkey.trim() -properties * |
		select  Name, 
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
			    #comment,
				description, 
				extensionAttribute8,
				Enabled				
		
	if ($AD_userlist.Keys -notcontains 	$u_res.SamAccountName) 
	{
        $AD_userlist[$xkey]=$u_res
	}
     
   return $u_res
}

Function NEW_get_AD_userlist
{ # Get-userlist from a given AD-Group  
  param(
        [string]$ad_group="dlg.WW.ADM-Services.P2V.access.production"
  )
  $cur_date        = (get-date)
  $max_age_minutes = 10 
  $refresh_list    =$true
  
  if (Get-ADGroup -identity ($ad_group))
  {
	# check if there is a pre-loaded list available
	
	  	  
      if($ADgroup_members.Keys -contains $ad_group)
      {  
        if (($cur_date -$($ADgroup_members[$ad_group].createdate)).totalminutes -gt $max_age_minutes) 
	      { # pre-loaded version outdated
	         $refresh_list   = $true  
		     clear-variable $($ADgroup_members[$ad_group])
          } else 
	      {  # preloaded version can be used
	         $refresh_list   = $false 
			 $entries = $ADgroup_members[$ad_group].list
	      }
      }
	  
      if ($refresh_list)
      {                                         
		write-host "refresh list $ad_group"
        $entries=Get-ADGroupMember -Identity $ad_group|select SamAccountName
        write-host "$($entries.count) xkeys loaded"
		# $entries|write-host #out-gridview -title "entries: $ad_group" -wait
 		$ADgroup_members[$ad_group] = New-Object PSObject -Property @{
		                               createdate = $cur_date
									   list       = @($entries.SamAccountName) 
									   count      = $entries.count
									   }
									   
		#$ADgroup_members[$ad_group]|ft|out-host
		#pause
		write-host "updating user details" 
         foreach ($u in $($ADgroup_members[$ad_group].list))
	     {
			#write-host "[$u]"
	
			if ($AD_userlist.Keys -notcontains 	$u) 
	        {
                  $u_res=NEW_get_AD_user -xkey $u
				  #$AD_userlist[$xkey]=$u_res
	        }
	        
            # write-host ($form1 -f "$u  [$($u_res.SamAccountName)]"		)
			#write-progress "updating user [$u]" -completed
	     }
		 write-host "updating users finished" 
		 # $AD_userlist|out-gridview -title "AD_userlist" -wait
	  } 
	
  }
  return @($entries.SamAccountName)
  #return $($ADgroup_members[$ad_group].list)
}



#---------------------------------------------------
Function get_AD_user
{ # function to verify and select user  via GUI 
  # return values:
  # $ad_user_selected:  FALSE in case of error
  # $ad_user_selected:  userprofile:
  #       Givenname,
  #       surname,
  #       SamAccountName, 
  #       EmailAddress, 
  #       comment, 
  #       Department, 
  #       lastlogon, 
  #       accountExpires,
  #       UserPrincipalName,
  #       displayName,
  #       logOnId
  #--------------------------------
   param (
        [string]$searchstring= "",
	    [string]$xkey=""
    )
   # $ad_user_selected=@{}
   
   # ask_continue -title "get_AD_user" -msg "xkey [$xkey] / searchstring [$searchstring]" -button 0 -icon 64 
  
   if ($xkey) {$searchstring=$xkey}
  
   while (!$ad_user_selected)
	 {
		$a =@{};
	 	while (-not $searchstring) {$searchstring="";  return $False}  ## ??? check
#		write-output ("found!!")
		if ($xkey -and ([ADSISearcher] "(sAMAccountName=$xkey)").FindOne()) 
		{ # valid x-key exists
		    
		   $u_res=Get-ADUser -identity $xkey.trim() -properties * |
		select  Name, 
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
			    comment,
				description, 
				extensionAttribute8,
				Enabled				
				if ($u_res) {write-progress "X-KEY [$xkey] found!!" }
		} else
		{ #no valid x-key -> take searchstring
			
		    $ad_user='*'+$searchstring.trim()+'*'
		
		    $u_res=Get-ADUser -SearchBase "DC=ww,DC=omv,DC=com" -Filter { (Givenname -like $ad_user) -or (Surname -like $ad_user) -or (Name -like $ad_user)} -properties * |
		    select  Name, 
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
				comment,
				description, 
				extensionAttribute8,
				Enabled			
				
				if ($u_res) {write-output "search string [$searchstring] found!!"}
	    }	
	    $u_count=$u_res.count  # was =0
		
		$searchstring="" # reset searchstr
 	   
		if ($debug) { $u_res|out-gridview -title "u_res" -wait }
		 
		#$ad_user_selected=$u_res | where {$_.Enabled -eq "True"} | select Givenname,surname,SamAccountName, EmailAddress,Enabled,  Department, lastlogon, accountExpires,UserPrincipalName,extensionAttribute8 #comment,
		$ad_user_selected=$u_res |  select Givenname,surname,SamAccountName, EmailAddress,Enabled,  Department, lastlogon, accountExpires,UserPrincipalName,extensionAttribute8 #comment,
				
			
		If (!$ad_user_selected) 
		{
		   $form_err -f "ERROR","[$u_res] not found or no user selected"|out-host
		   $ad_user_selected=""
		}
		else
		{
 	        $ad_user_selected|% { $_.lastLogon=[datetime]::FromFileTime($_.lastlogon).tostring('yyyy-MM-dd HH:mm:ss');
			                       $_.accountExpires=[datetime]::FromFileTime($_.accountExpires).tostring('yyyy-MM-dd HH:mm:ss') 
			                     } 
								 
			if ($u_count -gt 1) 
		    {
		          $ad_user_selected=$ad_user_selected|out-gridview -Title "select user from AD" -outputmode single
		    }	
			
		    #$ad_user_selected.lastLogon=[datetime]::FromFileTime($ad_user_selected.lastlogon).tostring('yyyy-MM-dd HH:mm:ss');
		    #$ad_user_selected.accountExpires=[datetime]::FromFileTime($ad_user_selected.accountExpires).tostring('yyyy-MM-dd HH:mm:ss') ; 
		 		 #    if ("$($ad_user_selected.distinguishedName)" -match "Deactivates") 	 {$ad_user_selected.comment="DEACTIVATED"} 
		 #		else															 {$ad_user_selected.comment="ACTIVE"}  
			
	        Add-Member -inputObject $ad_user_selected -Name 'displayName' -Type NoteProperty -Value "$($ad_user_selected.surname) $($ad_user_selected.Givenname) ($($ad_user_selected.SamAccountName))"
	        Add-Member -inputObject $ad_user_selected -Name 'logOnId' -Type NoteProperty -Value "$($ad_user_selected.UserPrincipalName)" 

    	    Add-Member -inputObject $ad_user_selected -Name 'OrgID'  -Type NoteProperty  -Value "$($ad_user_selected.extensionAttribute8)"				
     #      }
      #  catch{	
	#	    if (( ask_continue -title "ad_user_selected - get_AD_user_GUI" -msg "select / change user" -button 1 -icon 64 ) -eq "Cancel"){exit}
	 #        write-output $ad_user_selected|out-host
       #    }

			$ad_user_selected.PSObject.Properties.Remove('extensionAttribute8')	 
			         
		 	$ad_user_selected.Department=$ad_user_selected.Department -replace '[,]', ''
		    $ad_user_selected.Department=$($ad_user_selected.Department).trim()
		    $ad_user_selected.Department="$($ad_user_selected.OrgID):$($ad_user_selected.Department)"
	
		}
	  
	}	 
	#write-output "get_AD_user: `n$ad_user_selected"
	
    #	$ad_user_selected|out-gridview -wait
	Write-Progress -Completed -Activity "close progress bar"
	
    return $ad_user_selected	
} 

#---------------------------------------------------
Function get_AD_userlist
{ # Get-userlist from a given AD-Group  
   param(
   [string]$ad_group="dlg.WW.ADM-Services.P2V.access.production",
   [bool]  $all=$False
   )
   $refresh_list    = $true       # default to refresh list
   $cur_date        = (get-date)
   $max_age_minutes = 10     # max age of list in minutes
      
	if($ADgroup_members.Keys -contains $ad_group)
   {
   	   write-output ($form2_1 -f  $ad_group,$($ADgroup_members[$ad_group].createdate))
	   if (($cur_date -$($ADgroup_members[$ad_group].createdate)).totalminutes -gt $max_age_minutes) 
	   { # pre-loaded version outdated
	     $refresh_list   = $true  
		 clear-variable $($ADgroup_members[$ad_group])
       } else 
	   {  # preloaded version can be used
	     $refresh_list   = $false 
	   }
   }
   else   { $refresh_list   = $true }
    
   if ($refresh_list)
   {
      if ($check_group = Get-ADgroup -Identity $($ad_group))  #  OLD : -LDAPFilter "(SAMAccountName=$ad_group)")
      {
	    # AD group found
        $entries=Get-ADGroupMember -Identity $ad_group | Get-ADUser -properties * |Select Givenname,Surname,SamAccountName, EmailAddress, comment, Department, lastlogon, accountExpires,UserPrincipalName,extensionAttribute8
   
        $entries |%{ 
	        $_.lastLogon=[datetime]::FromFileTime($_.lastlogon).tostring('yyyy-MM-dd HH:mm:ss');
		    $_.accountExpires=[datetime]::FromFileTime($_.accountExpires).tostring('yyyy-MM-dd HH:mm:ss') ; 
		    if ("$($_.distinguishedName)" -match "Deactivates") 	 {$_.comment="DEACTIVATED"} 
				else															 {$_.comment="ACTIVE"} 
			
			Add-Member -inputObject $_ -Name 'displayName' -Type NoteProperty -Value "$($_.surname) $($_.Givenname) ($($_.SamAccountName))"
			Add-Member -inputObject $_ -Name 'logOnId'     -Type NoteProperty -Value "$($_.UserPrincipalName)" 
			Add-Member -inputObject $_ -Name 'OrgID'       -Type NoteProperty -Value "$($_.extensionAttribute8)";			
			$_.PSObject.Properties.Remove('extensionAttribute8')	 
			         
		 	$_.Department=$_.Department -replace '[,]', ''
		    $_.Department=$($_.Department).trim()
		    $_.Department="$($_.OrgID):$($_.Department)"
		           
		} 

        $ADgroup_members[$ad_group]=New-Object PSObject -Property @{
		                               createdate = $cur_date
									   list       = $entries 
									   count      = $entries.count
									   }

      } else
	  { #AD group not found
        $form_status -f "AD:  $ad_group","[ERROR]"
	    $entries=$false
	  }
   }
   
   $entries=$ADgroup_members[$ad_group].list
    
   if ($all)  { $ADgroup_members[$ad_group]=$entries }  # global list
   else    { $entries = $entries|out-gridview -title "select (multiple) user(s)" -outputmode multiple}
	
     
   return $entries
}

#---------------------------------------------------
Function get_AD_groups
{ # get AD-group member (incl. temp.storing)
   $all_adgroups = @{}
   $all_adgroups =import-csv $adgroupfile  
   






}

#---------------------------------------------------
Function get_AD_user_GUI 
{
	<#
      .SYNOPSIS
	
      .DESCRIPTION
	    get_AD_user_GUI opens a dialog box  to select AD user

      .PARAMETER msg <question>
	         shows the question (= content of dialog box)
		   	
	  .PARAMETER title <title>
	         sets the title of the dialog box
	

      .EXAMPLE
	      get_AD_user_GUI -title "Apply changes?" -msg "Apply changes to file xyz ?"
		  

	  .NOTES
       name:   get_AD_user_GUI 
       ver:    1.0
       author: M.Kufner
	   
	  .LINK

#>
   param (
        $msg= "enter xkey or searchstring: ",
		$title= "user selection"
    )
 
  $script:rc=$FALSE
 # $usr_sel = @{}
  $Readuser = New-Object system.Windows.Forms.Form
  $Readuser.ClientSize = '400,230'
  $Readuser.text = $title
  $Readuser.Font = 'Microsoft Sans Serif,10'
  $Readuser.Icon="$workdir/P2V.ico"
  $Readuser.Formborderstyle = "FixedDialog"
  # $Readuser.StartPosition    = "CenterScreen"
  $Readuser.Acceptbutton = $u_search_button
  $Readuser.Cancelbutton = $cancelbutton

  $u_label = New-Object system.Windows.Forms.Label
  $u_label.width = 180	
  $u_label.height = 20
  $u_label.location = New-Object System.Drawing.Point(15,15)
  $u_label.Font = 'Microsoft Sans Serif, 8.25pt'
  $u_label.Anchor= "Top,Bottom, Left, Right"
  $u_label.TextAlign = "MiddleRight"
  $u_label.Text = $msg

  $u_input = New-Object system.Windows.Forms.textbox
  $u_input.width = 175
  $u_input.height = 20
  $u_input.location = New-Object System.Drawing.Point(210,15)
  $u_input.Font = 'Microsoft Sans Serif, 8.25pt'
  $u_input.Anchor= "Top,Bottom, Left, Right"
  $u_input.TextAlign = "Left"
  $u_input.Text = "<user - xkey>"

  $u_search_button = New-Object system.Windows.Forms.Button
  $u_search_button.width = 140	
  $u_search_button.height = 25
  $u_search_button.location = New-Object System.Drawing.Point(130,45)
  $u_search_button.Font = 'Microsoft Sans Serif, 8.25pt'
  $u_search_button.Anchor= "Top,Bottom, Left, Right"
  $u_search_button.Text = "search user"
  $u_search_button.Add_Click({
     $adserver=Get-ADDomainController |select Hostname,Name,IPv4Address
	 $Userinfo.Lines =  "searching <$($u_input.Text)> in Active Directory"
	 $Userinfo.Lines += " contacting $($adserver.HostName) ($($adserver.IPv4Address))"
	 $Readuser.Refresh()
	 
	 # ask_continue -msg " global:usr_sel = get_AD_user -xkey $($u_input.Text)" -button 0
  	 $global:usr_sel = get_AD_user -xkey $u_input.Text
	 if ($global:usr_sel)
	 {
	    $Userinfo.Lines =  " "
	    $Userinfo.Lines += "user:           $($global:usr_sel.displayName)"
	    $Userinfo.Lines += "xkey:           $($global:usr_sel.SamAccountName)"
	    $Userinfo.Lines += "LogonID:        $($global:usr_sel.logOnId)"
	    $Userinfo.Lines += "Email:          $($global:usr_sel.EmailAddress)"
	    $Userinfo.Lines += "Department:     $($global:usr_sel.Department)"
	    $Userinfo.Lines += "Comment:        $($global:usr_sel.comment)"
		$Readuser.Acceptbutton = $okbutton
	 }else
	 {
		$Userinfo.Lines =  " error in search - please retry " 
	 }
	
	 $Readuser.Refresh()
  })

  $okbutton = New-Object system.Windows.Forms.Button 
  $okbutton.width = 140	
  $okbutton.height = 25
  $okbutton.location = New-Object System.Drawing.Point(15,195)
  $okbutton.Font = 'Microsoft Sans Serif, 8.25pt'
  $okbutton.Anchor= "Top,Bottom, Left, Right"
  $okbutton.Text = "continue"
  $okbutton.DialogResult = [System.Windows.Forms.DialogResult]::OK
  $okbutton.Add_Click({
    $script:rc=$True
    $Readuser.Close()
  })

  $cancelbutton = New-Object system.Windows.Forms.Button
  $cancelbutton.width = 140	
  $cancelbutton.height = 25
  $cancelbutton.location = New-Object System.Drawing.Point(245,195)
  $cancelbutton.Font = 'Microsoft Sans Serif, 8.25pt'
  $cancelbutton.Anchor= "Top,Bottom, Left, Right"
  $cancelbutton.Text = "Exit"
  $cancelbutton.DialogResult = [System.Windows.Forms.DialogResult]::ABORT
  $cancelbutton.Add_Click({
     $Readuser.Close()
  })


  $Userinfo = New-Object system.Windows.Forms.textbox
  $Userinfo.width = 370	
  $Userinfo.height = 100
  $Userinfo.location = New-Object System.Drawing.Point(15,80)
  $Userinfo.Font = 'Lucida Console,9'
  $Userinfo.multiline = $TRUE
  $Userinfo.ReadOnly = $TRUE
  $Userinfo.Anchor= "Top,Bottom, Left, Right"
  $Userinfo.TextAlign = "left"
  $Userinfo.Lines  = ""
  $Userinfo.BorderStyle="fixedsingle"
  
  $Readuser.Acceptbutton = $u_search_button
  $Readuser.Cancelbutton = $cancelbutton
  $Readuser.controls.AddRange(@($u_label,$u_input,$u_search_button,$okbutton,$cancelbutton,$UserInfo))
  $Readuser.ShowDialog()
   
  #return  $script:rc
 }
 
#---------------------------------------------------
Function P2V_export_AD_users
{
<#  documentation
.SYNOPSIS
	P2V_export_AD_users export P2V AD list to single csv file
.DESCRIPTION
	P2V_export_AD_users export P2V AD list to single csv file

.PARAMETER  outfile  <xxx>  
	define outputfile arguments
	
.PARAMETER  arguments <xxx>  
	describe 1 .. n arguments
	

.INPUTS
	none

.OUTPUTS
	true / false

.EXAMPLE
	Example of how to run the script.

.LINK
	Links to further documentation.

.NOTES
  
#>
$outfile= $output_path_base +"\P2V_SAMLusers_profiles_AUTO.csv"
P2V_header -app $MyInvocation.MyCommand -path $My_path 
createdir_ifnotexists -check_path $output_path_base  -verbose $true
Delete-ExistingFile -file $outfile

write-output ($form1   -f "exporting userlists  from Active Directory")

$sel_categories  = "SPECIAL","DATA","PROFILE"
$all_adgroups = @{}
$all_adgroups =import-csv $adgroupfile | where {($_.PSgroup -ne "") }
#$all_adgroups =import-csv $adgroupfile | where {($_.PSgroup -ne "") -and ($sel_categories -contains $_.category)}


# user collector
$all_users = @{}



Add-Content -Path $outfile -Value 'DisplayName,xkey,logonID,profile,ptype,Description,ADgroup'

foreach ($a in $all_adgroups)
{
	$usr= @{}
	write-progress "checking  $($a.ADgroup)"
	if ($check_group = Get-ADGroup -identity $a.ADgroup )
    {
		$members= @{}
		write-progress "loading  $($a.ADgroup)"
		
	   $members=Get-ADGroupMember -Identity $a.ADgroup|select Name
	   $members|% {
		  
   	   if ($all_users.keys -notcontains $_.Name )
		  { 
		     $all_users["$($_.Name)"]=get_AD_user -xkey $_.Name 
		     
		  }
	      $usr= $all_users["$($_.Name)"]
		  Add-Content 	-Path $outfile -Value "$($usr.displayName),$($usr.SamAccountName),$($usr.logOnId),$($a.PSgroup),$($a.category),$($usr.Description),$($a.ADgroup)"    
	   }
	   #write-output ($form2 -f  "[$($members.count)]","users loaded from $($a.ADgroup)")
	   Write-Output -NoEnumerate ($form_status -f "$($a.ADgroup)",("[{0,3}]" -f $($members.count)))
	
	}	
}
write-progress "loading finished" -completed
write-output ($form1 -f "result are stored in $outfile")	
 P2V_footer -app $MyInvocation.MyCommand	
}

#=================================================================
# Exports
#=================================================================

Export-ModuleMember -Variable '*'
Export-ModuleMember -Function * -Alias *