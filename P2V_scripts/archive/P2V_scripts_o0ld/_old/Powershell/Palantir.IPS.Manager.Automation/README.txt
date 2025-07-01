Aucerna PlanningSpace 16.4: IPS PowerShell Module (Automation cmdlets)
======================================================================

The IPS PowerShell module provides a set of cmdlets that can be used to perform administrative 
tasks for a PlanningSpace deployment. You can include the cmdlets in PowerShell scripts to 
automate tasks.


INSTALLATION: IPS SERVER
------------------------

The module is installed automatically as part of an IPS Server installation. (The files are 
installed in the 'Palantir' programs folder, for example 
'C:\Program Files\Palantir\PalantirIPS 16.4\Powershell', and the Windows environment variable 
'$env:PSmodulepath' is modified to include this folder.) You do not need to do any further 
installation if you are using the module on an IPS Server machine.

You can test that the module is installed correctly with the following PowerShell command:

PS> Get-Command -Module Palantir.IPS.Manager.Automation

You should see a listing of all of the cmdlets.

Note: The module requires at minimum version 3.0 of PowerShell.


MANUAL INSTALLATION
-------------------

You need to have a copy of the folder 'Palantir.IPS.Manager.Automation' which contains
all of the IPS PowerShell module files (including this file).

To get the folder you can download the PowerShell module ZIP file from the Client Center website 
at https://clients.palantirsolutions.com/products/downloads . The filename will be of the form
'Palantir.IPS.Manager.Automation_16.4.0.979.zip' (the version number needs to match the version
of PlanningSpace that you will be using).

Your PSModulePath variable for PowerShell should look something like this, by default:

PS> $env:PSmodulepath
C:\Users\{USERNAME}\Documents\WindowsPowerShell\Modules;C:\Program 
Files\WindowsPowerShell\Modules;C:\Windows\system32\WindowsPowerShell\v1.0\Modules

If you are non-Administrator user then add the 'Palantir.IPS.Manager.Automation' module to your own 
folder 'Documents\WindowsPowerShell\Modules':
1.	Create a folder 'C:\Users\{USERNAME}\Documents\WindowsPowerShell\Modules' (if it does not exist)
2.	Paste in a copy of the folder 'Palantir.IPS.Manager.Automation'
3.	Check it is working with the command 'Get-Command –Module Palantir.IPS.Manager.Automation' which 
    should list all of the cmdlets in the module

If you are an Administrator user you can make the module available to all users of a machine by adding 
the 'Palantir.IPS.Manager.Automation' folder to 'C:\Program Files\WindowsPowerShell\Modules'.


USING THE CMDLETS
-----------------

All of the cmdlets, except for 'Test-Server', require an IPS server login with 'Connect-IPSManager'. 
A successful connection will look like the following:

PS> Connect-IPSManager https://ips.mycompany.com
IsSuccess            : True
Errors               : 
Url                  : https://ips.mycompany.com
ServerVersion        : 16.4.0.1053
UserName             : MYCOMPANY\ipsadmin
IsMemberOfAdminGroup : True
IsServerLicensed     : True

The authentication of your connection is based on the Windows user account that executes the 
'Connect-IPSManager' command. The account must be a member of the IPS Administrators Group.

You should disconnect from the server when the connection is no longer required:

PS> Disconnect-IpsManager

Note on connection to an IPS server cluster: When you connect to a cluster of server machines, 
you have the option to connect via the load balancer, which will automatically select a server machine 
to connect to, or to connect directly to a specific server machine. There are a few cmdlets intended for 
use with specific servers, for adding or removing machines to/from a cluster, or changing the primary 
server machine: 'Get-IsPartOfCluster', 'Get-IsPrimaryServer', 'Join-ClusterAsPrimaryServer', and 
'Join-ClusterAsSecondaryServer'.


USING THE MODULE HELP INFORMATION
---------------------------------

The cmdlets follow the standard PowerShell 'verb-noun' convention.

The module contains comprehensive help information for all of the cmdlets. Use 'Get-Help' with a 
cmdlet name to access its help information. For example:

PS> Get-Help Get-TenantClusterTempFolder -full

You can use the Windows Powershell ISE tool to explore the contents of the module: open the Command add-on 
and in the 'Module' selection box select 'Palantir.IPS.Manager.Automation'.

