#reg query "HKEY_CURRENT_USER\Software\Google\Chrome\BLBeacon" /v version

$apps_to_check=@(
#  "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
#  "C:\Program Files\Google\Chrome\Application\chrome.exe",
#  "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
#  "C:\Program Files\Microsoft\Edge\Application\msedge.exe",
  "C:\Program Files\Notepad++\notepad++.exe"
  )
  
 # $apps_to_check= $apps_to_check|Out-GridView -Title "select app(s) for versioncheck" -outputmode multiple
Foreach ($c in $apps_to_check)
{
if (test-path $c)  {

(get-item $c).versioninfo|select Productname, Productversionraw, Language|ft
}
}

#\\somvat202005\AUCERNA_INSTALL\Admin\Chrome\GoogleChromeStandaloneEnterprise64.msi