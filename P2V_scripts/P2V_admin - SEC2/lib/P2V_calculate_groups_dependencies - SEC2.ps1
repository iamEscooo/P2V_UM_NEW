#=======================
#  calculate_group_dependencies_SEC2
#
#  name:   calculate_group_dependencies-SEC2.ps1 
#  ver:    1.0
#  author: M.Kufner
#=======================
Function P2V_calculate_groups_dependencies
{
<#
.SYNOPSIS
	calculate_group_dependencies checks datagroup dependencies
.DESCRIPTION
	

.PARAMETER menufile <filename>
	CSV file 
	
.PARAMETER xamldir <directory>
	CSV file 
	
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
	Detail on what the script does, if this is needed.

#>
  param(
    [string]$allow="",
    [string]$readonly="",
    [string]$deny="",
    [string]$tenant="",
    [bool]$checkonly = $FALSE,
  #[bool]$checkonly = $true,
    [bool]$debug = $false
  )

  #----- Set config variables

  $output_path = $output_path_base + "\$My_name"
  $P2V_U      = @{}   # userlist  from P2V
  $P2V_G      = @{}   # grouplist from P2V
  $P2V_UG	    = @{}   # U-G assignment
  $updateOperations   = @{}   # change-operations  for bulk load based on groups
  $change_ops = @{}
  # from P2V_include
  # $data_groups

  $Eco_groups= @("A13.profile.Economics.Classic","A14.profile.Economics.Regimes","A15.profile.Economics.Plus")
  $Fin_groups= @("A16.profile.Finance.Classic","A17.profile.Finance.Regimes","A18.profile.Finance.Plus")
  $PP_groups=  @("A10.profile.Planning.Classic","A11.profile.Planning.Plus")
  $RES_groups= @("A20.profile.Reserves.local.QRE","A21.profile.Reserves.Headoffice","A22.profile.Reserves.Headoffice.Power","A23.profile.Reserves.Headoffice.Approve")
  $Port_groups= @("A19.profile.Portfolio.Classic")
  $port_countries= @("data.Bulgaria","data.Corporate","data.Georgia","data.Romania")
  $CAPDAT_groups= @("A03.profile.CAPDAT")
  $Exp_groups= @("A24.profile.Exploration.Assurance")
  $Exp_countries= @("data.Corporate")

  # license groups
  $heavy="license.heavy"
  $light="license.light"

  P2V_header -app $MyInvocation.MyCommand -path $My_path 

   
  $data_countries= import-csv $data_groups -Encoding UTF8
  #$data_countries |format-table
  write-output ($form1 -f "select the tenant(s) to check the data-group dependenciese" )
  
  $tenants= select_PS_tenants -multiple $true

  foreach ($ts in $tenants.keys)
  {
    $t           = $tenants[$ts]
    $tenant      = $t.tenant
    $tenantURL  ="$($t.ServerURL)/$($t.tenant)"
    $base64AuthInfo = $t.base64AuthInfo      
   
   
    write-output ($form1 -f ">> checking $tenant" )
   
    $all_users = get_PS_userlist -tenant $t 
    $all_users = $all_users|where { ($_.authenticationMethod -eq "SAML2") }
    $all_users = $all_users|where { ($_.IsDeactivated -ne $true) }
    $all_users  | % {$P2V_U["$($_.logonID)"]=$_}
   
    $all_groups= get_PS_grouplist -tenant $t 
    $all_groups | % {$P2V_G["$($_.name)"]=$_}
      
  
    foreach ($currentuser in $P2V_U.keys)
    {
      $eco=$false
      $fin=$false
      $pp=$false
   	  $res=$false
	  $port=$false
	  $capdat=$false
	  $explore=$false
	 
      #$p2v_u[$currentuser]|format-list
	  $hash = @{}
	  
	  #$form2_1 -f $currentuser,$tenant
	  
      foreach($tmpgroups in $P2V_U[$currentuser].userWorkgroups)
	  {
      
           #$tmpgroups | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($tmpgroups | SELECT -exp $_) }
		   $tmpgroups | Get-Member -MemberType Properties | select -exp "Name" | % { $P2V_UG[$currentuser]+= @($($tmpgroups | SELECT -exp $_).name)  }
            #$tmpgroups|format-table|out-host
				
		#	$tmpgroups.keys|% {$P2V_UG[$currentuser]+= @($($tmpgroups["$_"].name)) }
      }
	   
      #	   $P2V_UG["$currentuser"]   |out-host
	  Foreach ($g in $eco_groups) {if ($P2V_UG["$currentuser"] -contains $g) {$eco=$true} else {$eco=$eco -or $false} }
	  Foreach ($g in $fin_groups) {if ($P2V_UG["$currentuser"] -contains $g) {$fin=$true} else {$fin=$fin -or $false} }
	  Foreach ($g in $PP_groups)  {if ($P2V_UG["$currentuser"] -contains $g) {$pp=$true} else {$pp=$pp -or $false} }
      Foreach ($g in $RES_groups)  {if ($P2V_UG["$currentuser"] -contains $g) {$res=$true} else {$res=$res -or $false} }
	  Foreach ($g in $Port_groups) {if ($P2V_UG["$currentuser"] -contains $g) {$port=$true} else {$port=$port -or $false} }
	  Foreach ($g in $CAPDAT_groups) {if ($P2V_UG["$currentuser"] -contains $g) {$capdat=$true} else {$capdat=$capdat -or $false} }
	  Foreach ($g in $Exp_groups) {if ($P2V_UG["$currentuser"] -contains $g) {$explore=$true} else {$explore=$explore -or $false} }
	  
	   
	  #$form4 -f "[$currentuser]","eco: $eco","fin: $fin","pp: $pp"
	   
	  $uid=$P2V_U["$currentuser"].id
	  $add_ops  = [PSCustomObject]@{
          op    = "add"
          path  = "/users/$uid"
          value = ""
      }
	  $del_ops  = [PSCustomObject]@{
          op    = "remove"
          path  = "/users/$uid"
          value = ""
      }
	   	   
      Foreach ( $country in $data_countries)
	  {
	    if ($P2V_UG["$currentuser"] -contains $country.data)
		{
		  # $form1 -f "checking $($country.data)"
		  #--- check economic rule (eco_groups AND	data.country ->	ADD	data.country.Economics)

		  if ($eco -and ($P2V_UG["$currentuser"] -notcontains $($country.eco))) 
	      { 
			$updateOperations["$($P2V_G[$($country.eco)].id)"] += @($add_ops)
			write-output ( $form_user -f "[ADD]",$currentuser, $($country.eco))
		  }
		  if (-not $eco  -and ($P2V_UG["$currentuser"] -contains $($country.eco)))
		  {
		    $updateOperations["$($P2V_G[$($country.eco)].id)"] += @($del_ops)
			write-output ( $form_user -f "[DEL]",$currentuser, $($country.eco))
		  }
		  
		  # else
          #{ $form1 -f "$($countr.eco) already exists"}			  
		  #--- check financial rule (fin_groups AND	data.country ->	ADD	data.country.Financial)
		  if ($fin -and ($P2V_UG["$currentuser"] -notcontains $($country.fin))) 
		  { 
		    $updateOperations["$($P2V_G[$($country.fin)].id)"] += @($add_ops)
		    write-output ( $form_user -f "[ADD]",$currentuser, $($country.fin))
				
		  }
		  if (-not $fin -and ($P2V_UG["$currentuser"] -contains $($country.fin))) 
		  { 
		    $updateOperations["$($P2V_G[$($country.fin)].id)"] += @($del_ops)
		    write-output ( $form_user -f "[DEL]",$currentuser, $($country.fin))
				
		  }
		  # else
          #{ $form1 -f "$($countr.fin) already exists"}		
		  #--- check Planning rule (pp_groups AND	data.country ->	ADD	data.country.Planning)
		  if ($pp -and ($P2V_UG["$currentuser"] -notcontains $($country.key))) 
		  { 
			   
		    $updateOperations["$($P2V_G[$($country.key)].id)"] += @($add_ops)
			write-output ( $form_user -f "[ADD]",$currentuser, $($country.key))
		  } 
		  if (-not $pp -and ($P2V_UG["$currentuser"] -contains $($country.key))) 
		  { 
			   
		    $updateOperations["$($P2V_G[$($country.key)].id)"] += @($del_ops)
			write-output ( $form_user -f "[DEL]",$currentuser, $($country.key))
		  } 
		  #else
          #{ $form1 -f "$($countr.pp) already exists"}	
		  #--- check reserves rule (res_groups AND	data.country ->	ADD	data.country.Reserves)
		  if ($res -and ($P2V_UG["$currentuser"] -notcontains $($country.res))) 
		  { 
			   
		    $updateOperations["$($P2V_G[$($country.res)].id)"] += @($add_ops)
			write-output ( $form_user -f "[ADD]",$currentuser, $($country.res))
		  } 
			  
		  if (-not $res -and ($P2V_UG["$currentuser"] -contains $($country.res))) 
		  { 
			   
		    $updateOperations["$($P2V_G[$($country.res)].id)"] += @($del_ops)
			write-output ( $form_user -f "[DEL]",$currentuser, $($country.res))
		  } 
	      #--- check portfolio rule (port_groups AND	data.country ->	ADD	data.country.Portfolio)		  
		  if  ($port_countries -contains $country)
		  {
			if ($port -and ($P2V_UG["$currentuser"] -notcontains $($country.port))) 
			{ 
			   
				$updateOperations["$($P2V_G[$($country.port)].id)"] += @($add_ops)
				write-output ( $form_user -f "[ADD]",$currentuser, $($country.port))
			} 
			  
			if (-not $port -and ($P2V_UG["$currentuser"] -contains $($country.port))) 
			{ 
			   
				$updateOperations["$($P2V_G[$($country.port)].id)"] += @($del_ops)
				write-output ( $form_user -f "[DEL]",$currentuser, $($country.port))
			}
		  }	

		   #--- check CAPDAT rule (CAPDATgroups AND	data.country ->	ADD	data.country.CAPDAT)		  
		  
		  if ($capdat -and ($P2V_UG["$currentuser"] -notcontains $($country.CAPDAT))) 
		  { 
			   
		    $updateOperations["$($P2V_G[$($country.CAPDAT)].id)"] += @($add_ops)
			write-output ( $form_user -f "[ADD]",$currentuser, $($country.CAPDAT))
		  } 
			  
		  if (-not $capdat -and ($P2V_UG["$currentuser"] -contains $($country.CAPDAT))) 
		  { 
			   
		    $updateOperations["$($P2V_G[$($country.CAPDAT)].id)"] += @($del_ops)
			write-output ( $form_user -f "[DEL]",$currentuser, $($country.CAPDAT))
		  } 
		  #else
          #{ $form1 -f "$($countr.pp) already exists"}	
 		   
		  		   
		   
		  }
	         	   
	  }

      # license checks
	   
	   $l_h=$false
       $l_l=$false
	   
	   if ($P2V_UG["$currentuser"] -contains $heavy) {$l_h=$true}
       if ($P2V_UG["$currentuser"] -contains $light) {$l_l=$true}
   
       if ($l_h -and $l_l) 
       {
         
         $form_user -f "[DEL]",$currentuser, $light
		 $change_ops  = [PSCustomObject]@{
                                op = "remove"
                                path = "/users/$uid"
                                value = ""
						}
		 $updateOperations["$($P2V_G[$light].id)"] += @($change_ops)
       }
       if (!$l_h -and !$l_l) 
       {
                  
		 $form_user -f "[ADD]",$currentuser, $light
		 $change_ops  = [PSCustomObject]@{
                                op = "add"
                                path = "/users/$uid"
                                value = ""
						}
		 $updateOperations["$($P2V_G[$light].id)"] += @($change_ops)
       }
	  
	}
	
if ($updateOperations.Count -gt 0) {$linesep }
if (($updateOperations.Count -gt 0) -and (($cont=ask_continue -title "Apply changes?" -msg " apply then listed changes to the user/workgroup assignments?") -like "Yes") )

{

  $body=$updateOperations|convertto-json		
#  $body

  $apiUrl = "$($tenantUrl)/planningspace/api/v1/workgroups/bulk"	
  $i_result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers @{'Authorization' = "Basic $base64AuthInfo"} -Body ( $body ) -ContentType "application/json"
 
  if ($i_result["$_"]) 
      {$form_status -f  $line, "[DONE]"} else
      {$form_status -f  $line, "[ERROR]"} 

} else {$form1 -f "no changes applied"}
 $linesep
}

# $P2V_g|format-table|out-host
# $linesep
# pause

#$P2V_u|format-table|out-host
#$linesep
#pause
	 
  P2V_footer -app $MyInvocation.MyCommand
}
# ----- end of file -----

