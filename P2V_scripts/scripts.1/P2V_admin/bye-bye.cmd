@echo off
PowerShell -Command "Add-Type -AssemblyName PresentationFramework;if ([System.Windows.MessageBox]::Show('Continue with LOGOFF ?','Confirmation',1) -eq 'OK') {logoff}"