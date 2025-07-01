

Get-ChildItem -Path cert:\LocalMachine\My |format-table SerialNumber, Friendlyname,notbefore, notafter, Issuer, subject

#netsh http show sslcert ipport=0.0.0.0:443

#
#netsh http delete sslcert ipport=0.0.0.0:443

#netsh http add sslcert ipport=0.0.0.0:443 certhash=   appid="{4dc3e181-e14b-4a21-b022-59fc669b0914}"