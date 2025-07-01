param(
  [string]$workdir="\\somvat202005\PPS_Share\P2V_scripts",
  [bool]$analyzeOnly = $True
)
#-------------------------------------------------
#  Set config variables

#$workdir     = "\\somvat202005\PPS_Share\P2V_scripts"

$config_path = $workdir + "\config"
$adgroupfile = $config_path + "\all_adgroups.csv"
$tenantfile  = $config_path + "\all_tenants.csv"
$output_path = $workdir + "\output\AD-groups"
$u_w_file= $output_path + "\Myuserworkgroup.csv"
$OMV_domain="ww"

$linesep="+----------------------------------------------------+
"

#-------------------------------------------------
#----- functions
# Function to get all PlanningSpace workgroups
Function Get-PlanningSpaceWorkgroups($tenantUrl, $token)
{
  $apiUrl = $tenantUrl + "/PlanningSpace/api/v1/workgroups"
  $hash = @{}
  $workgroups = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers @{"Authorization"="Bearer " + $token} 
  foreach ($i in $workgroups) {$hash[$($i.id)]=$($i.name) }

  return $hash
}

# Function to get all PlanningSpace Windows AD users
Function Get-PlanningSpaceUsers($tenantUrl, $token)
{
  $apiUrl = $tenantUrl + "/PlanningSpace/api/v1/users?include=UserWorkgroups"
  $users = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers @{"Authorization"="Bearer " + $token} 
  $domainUsers = $users #| Where-Object { $_.authenticationMethod -eq "WINDOWS_AD" }
  return $domainUsers
}

#-------------------------------------------------
#----- start main part

#---  function to check Active Directory  ---
function Check_User_AD ($user)
{
  $result=@()

#----- check whether xkey exists in AD and retrieve core information
  write-host $linesep
  write-host "         Active Directory
    .. searching for $user     "

  $result=Get-ADUser -Filter {Name -like $user} -properties * |select Name,GivenName,Surname,UserPrincipalName,SamAccountName,EmailAddress,Country,Company,Department,EmployeeNumber, Enabled, HomeDirectory ,PasswordExpired ,LockedOut,lockoutTime

  if(!$result) 
  { 
    write-Host -ForegroundColor Red "  !! [$user] does not exist !!" 
  } else     
  { 
    $result 

#----- check whether xkey is member of ADgroups of P2V
    Write-Host "$linesep  P2V AD group memberships for $($result.SamAccountName)

"

    foreach ($i in import-csv $adgroupfile)
    {
      if (Get-ADGroupMember -Identity $($i.ADgroup)|where {$($_.SamAccountName) -eq $($result.SamAccountName)}) 
      { $i.ADgroup }
    }
  }
} # end of Check_User_AD


function Check_User_PS ()
{
#----- check whether xkey is member of workgroups in P2V
    Write-Host "
    $linesep  P2V Planningspace group memberships for $($result.SamAccountName)
"

   

    foreach ($i in $all_systems)
    {
      $out        =" > {0,-15}: " -f $($i.tenant)
	  $authURL    ="$($i.ServerURL)/identity/connect/token"
      $tenantURL  ="$($i.ServerURL)/$($i.tenant)"
          
      write-host "$out"

    # start authentication 
      $authResponse = Invoke-RestMethod -Method Post -Uri $authURL -headers @{'Content-Type'= 'application/x-www-form-urlencoded'} -body "grant_type=password&username=$($i.usern)&password=$($i.passw)&scope=planningspace&client_id=$($i.tenant)+resource_owner&client_secret="
       
    # retrieve all users incl. workgroups
      $resp=Invoke-RestMethod -Uri "$tenantURL/PlanningSpace/api/v1/users?include=UserWorkgroups" -header @{'Authorization' = 'Bearer ' + $authResponse.access_token} #|where {$($_.logOnId) -like $($result.SamAccountName)}
      $resp=$resp |select logOnId, displayName, isDeactivated, isAccountLocked, userWorkgroups |where {$($_.logOnId) -like $($result.SamAccountName)}
    
      if ($resp) 
      {
        "    - {0}({1}) is deactivated: {2,6} " -f $($resp.logOnId),$($resp.displayName),$($resp.isDeactivated)
        "    - {0}({1}) is locked     : {2,6}" -f $($resp.logOnId),$($resp.displayName),$($resp.isAccountLocked)
        write-host -nonewline "    - workgroups: "    
    
        foreach($tmpWgs in $($resp.userWorkgroups))
        {
          $hash = @{}
          $tmpWgs | Get-Member -MemberType Properties | select -exp "Name" | % { $hash[$_] = ($tmpWgs | SELECT -exp $_) }
         
          foreach($wg in ($hash.Values | Sort-Object -Property Name))
          {
            $groupsHash = @{}
            $wg | Get-Member -MemberType Properties | select -exp "Name" | % { $groupsHash[$_] = ($wg | SELECT -exp $_) }
            write-host -nonewline  "["$groupsHash["name"]"] "
          }
        }
        Write-host "
       "
        } else 
        {
          write-host -ForegroundColor Red "    $($result.SamAccountName) does not exist"
        }
      }
    
  write-host $linesep
} # end Check_User_PS

#--  event handler click_check

$click_check = {
 $Output.Text = $Output.Text.Clear
 
 $usr=$($textinput.Text)|out-string #-NoNewline

 if ($CheckBox1.checked) 
 { 
      
   $Output.Appendtext("Checking AD  for :$usr")
 }
 if ($CheckBox2.checked) 
 { 
   
   $Output.Appendtext("Checking PS  [$usr]")
 } 

}


function P2V_dialog 
{
<# This form was created using POSHGUI.com  a free online gui designer for PowerShell
.NAME
    Untitled
#>

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form1                           = New-Object system.Windows.Forms.Form
$Form1.ClientSize                = '640,480'
$Form1.text                      = "Check P2V User account"
$Form1.TopMost                   = $false

$button1                         = New-Object system.Windows.Forms.Button
$button1.text                    = "Check user"
$button1.width                   = 100
$button1.height                  = 30
$button1.location                = New-Object System.Drawing.Point(115,435)
$button1.Font                    = 'Microsoft Sans Serif,10'
$button1.Add_Click($click_check)
$button1.Add_Enter($click_check)


$button2                         = New-Object system.Windows.Forms.Button
$button2.text                    = "Exit"
$button2.width                   = 100
$button2.height                  = 30
$button2.location                = New-Object System.Drawing.Point(425,435)
$button2.Font                    = 'Microsoft Sans Serif,10'
$button2.Add_Click({$Form1.Close()})


$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Enter X-Key to check:"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(15,15)
$Label1.Font                     = 'Microsoft Sans Serif,10'

$textinput                       = New-Object system.Windows.Forms.TextBox
$textinput.multiline             = $false
$textinput.width                 = 100
$textinput.height                = 20
$textinput.location              = New-Object System.Drawing.Point(160,12)
$textinput.Font                  = 'Microsoft Sans Serif,10'
$textinput.Text                  = "<enter xkey >"

$CheckBox1                       = New-Object system.Windows.Forms.CheckBox
$CheckBox1.text                  = "Check Active Directory"
$CheckBox1.AutoSize              = $false
$CheckBox1.width                 = 200
$CheckBox1.height                = 20
$CheckBox1.location              = New-Object System.Drawing.Point(15,70)
$CheckBox1.Font                  = 'Microsoft Sans Serif,10'

$CheckBox2                       = New-Object system.Windows.Forms.CheckBox
$CheckBox2.text                  = "Check Planningspace"
$CheckBox2.AutoSize              = $false
$CheckBox2.width                 = 200
$CheckBox2.height                = 20
$CheckBox2.location              = New-Object System.Drawing.Point(15,90)
$CheckBox2.Font                  = 'Microsoft Sans Serif,10'

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "Select Tenants to check:"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(280,15)
$Label2.Font                     = 'Microsoft Sans Serif,10'

$Listbox                         = New-Object system.Windows.Forms.Listbox
$Listbox.width                   = 200
$Listbox.height                  = 82
$all_tenants                    | ForEach-Object {[void] $Listbox.Items.Add($_)}
$Listbox.location                = New-Object System.Drawing.Point(280,40)
$Listbox.Font                    = 'Microsoft Sans Serif,10'
$Listbox.SelectionMode           = 'MultiExtended'

$Output                          = New-Object System.Windows.Forms.RichTextBox 
$Output.text                     = "< enter x-key and press [Check user] >"
$Output.width                    = 600
$Output.height                   = 300
$Output.location                 = New-Object System.Drawing.Point(15,120)
$Output.MultiLine                = $True 
$Output.ScrollBars               = "Vertical" 
$Output.Font                     = 'Courier New,8'


$Form1.controls.AddRange(@($button1,$button2,$textinput,$CheckBox1,$CheckBox2,$Listbox,$Output,$Label1,$Label2))


#main part
$Form1.Add_Shown({$Form1.Activate()})
[void]$Form1.ShowDialog()
}
 
 
# /--  main part --/


$all_systems = @()
$all_tenants = @()
$all_systems =import-csv $tenantfile
Foreach ($i in $all_systems){$all_tenants += $($i.tenant)}


P2V_dialog 



