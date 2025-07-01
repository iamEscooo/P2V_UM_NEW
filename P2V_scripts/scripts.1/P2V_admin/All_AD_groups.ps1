$adgroups= @{}
$out_string="{0,-60} :: {1,-40} *{2,-25}  [{3,5}]"

$adgroups=Get-ADGroup -Filter { (Name -like "*P2V*" -or Name -like "*PetroVR*")} -properties * #   dlg.WW.ADM-Services.P2V.testusers
#$adgroups=Get-ADGroup -LDAPFilter "(SAMAccountName=*P2V*) | (SAMAccountName=*PetroVR*) )" -Properties *  #-or (SAMAccountName=*PetroVR*)"
#$adgroups=Get-ADGroup -LDAPFilter "(SAMAccountName=dlg.WW.ADM-Services.P2V.testusers)" -Properties *  #-or (SAMAccountName=*PetroVR*)"

$adgroups=$adgroups|select Name ,mail,created ,modified,extensionAttribute5,description|out-gridview  -title "relevant AD groups found"  -outputmode multiple
#$adgroups|format-list|more
$adgroups.count

# 'GroupCategory -eq "Security" -and GroupScope -ne "DomainLocal"'
$adgroups|select Name,description|ft