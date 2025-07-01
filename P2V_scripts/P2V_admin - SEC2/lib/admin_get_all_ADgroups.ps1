
Get-ADgroup -Filter '(ObjectClass -eq "group" -and (sAMAccountName -like "dlg.WW.ADM-Services.P2V*" -or sAMAccountName -like "dlg.WW.ADM-Services.PetroVR*") )' |select SamAccountName