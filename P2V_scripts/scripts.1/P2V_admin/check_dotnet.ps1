#reg query "HKEY_CURRENT_USER\Software\Google\Chrome\BLBeacon" /v version

 Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"|select Targetversion,Version,release |ft