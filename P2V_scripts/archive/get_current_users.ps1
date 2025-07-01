#requires -version 4.0
# ___ ___ _____ ___
#| _ \ _ \_   _/ __|
#|  _/   / | || (_ |
#|_| |_|_\ |_| \___|
# Active PRTG Users
# ================================
# This script will show you the PRTG users that are currently logged in or have logged in today. 
# NOTE: Please don't configure intervals lower than five minutes as it will lead to performance issues otherwise.
#
# Version History
# ----------------------------
# 1.2      Updated to new logging paths of PRTG 18.3.43. Invalid SSL certificates will also work properly now.
# 1.1      Switched to reading users via webinterface. 
# 1.05     Changed search method, now takes 0.14s for every user instead of ~3s in large log files
#          Better debugging output
# 1.01     Updated comments and documentation
# 1.0      initial release
# # # # # # # # # # # # # # # # # # # # # # # # # #
param( 
       [string]$prtgProtocol = "http",
          [int]$prtgPort     = 80, 
       [string]$prtgHost     = "your.prtg.com", 
       [string]$prtgUser     = "prtgadmin", 
       [string]$prtgPasshash = "12345678"
)


function Console-ShowMessage([string]$type,[string]$message){
        Write-Host ("[{0}] " -f (Get-Date)) -NoNewline;
        switch ($type){
            "success"       { Write-Host "    success    "  -BackgroundColor Green      -ForegroundColor White -NoNewline; }
            "information"   { Write-Host "  information  "  -BackgroundColor DarkCyan   -ForegroundColor White -NoNewline; }
            "warning"       { Write-Host "    warning    "  -BackgroundColor DarkYellow -ForegroundColor White -NoNewline; }
            "error"         { Write-Host "     error     "  -BackgroundColor DarkRed    -ForegroundColor White -NoNewline; }
            default         { Write-Host "     notes     "  -BackgroundColor DarkGray   -ForegroundColor White -NoNewline; }
        }
        Write-Host (" {0}{1}" -f $message,$Global:blank) 
}

#region configuration
$progressPreference = 'silentlyContinue'

# ignore invalid ssl certs
add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy


# The list of the users
$Users = New-Object System.Collections.ArrayList;

# We'll need the current date to get the correct log file
[string] $currentDate     = (date -format "yyyyMMdd");

# Extract the correct data path from the registry
[string] $LogFilePath     = ((Get-ItemProperty -Path "hklm:SOFTWARE\Wow6432Node\Paessler\PRTG Network Monitor\Server\Core" -Name "Datapath").DataPath) + "Logs\webserver\WebServer.log"

# Get the content of the log file 
[string[]]$LogFileContent = (Get-Content $LogFilePath);

#endregion

function This-GetLogLines([string]$searchstring){
    
    $Lines = ($LogFileContent -match $searchstring)

    if($Lines) { return $Lines;  }
    else       { return $false; }

}

# This will retrieve all active users from the configuration file and compare them to the webserver log
function This-GetUsers(){

    begin { 
        Console-ShowMessage -type information -message "Using $($LogFilePath)"
        Console-ShowMessage -type information -message "Log is $($LogFileContent.Count) lines long";
        Console-ShowMessage -type information -message "Loading Users..."
    }

    process {
        # uncomment the following line if you've forced TLS 1.2 in PRTGs webinterface
        # [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        # Receive the current PRTG user list   
        try   {$Object = (Invoke-Webrequest -Uri ([string]::Format("{0}://{1}:{2}/config_report_users.htm?username={3}&passhash={4}", $prtgProtocol,$prtgHost, $prtgPort,$prtgUser, $prtgPasshash)) -SessionVariable PRTG)}
        catch { 
            Console-ShowMessage -type error -message "Could not access PRTG webinterface. Please check URL and credentials!";  
            Write-Host "0:Could not access PRTG webinterface. Please check URL and credentials!"    
            #exit 1;  
        }
        
        Foreach($Link in $Object.Links){
            if($Link.OuterHTML -match "edituser.htm" -and [int]$Link.Id)
            { $User = New-Object PSObject –Property @{UserName = $Link.InnerHtml; UserID = $Link.Id}; $Users.Add($User) | Out-Null }
        }
     
           # Get a list of all active users in PRTG - others can't login anyway. 
           Console-ShowMessage -type success -message "Found $($Users.Count) users"; 

           # For every active user in the list ...
           $loggedInUsers = Foreach($User in $Users){

              Console-ShowMessage information "Checking $($User.UserName)"
              #...get the last entry of the user
              $Result = (This-GetLogLines -searchstring "user$($User.UserId)"); 
          
              if($Result)
              { Console-ShowMessage information "$($Result.Length) log entries for this user." -nonewline }
          
              # If the last entry of the user matches logout, he isn't logged in
              $LastEntry = $Result[$Result.Length-1]

              if($LastEntry -match "logout")
              { $LoggedIn = "No" }      

              # If any of the above is not the case, he's logged in. Fill the variables accordingly
              elseif($LastEntry)
              { $LoggedIn = "Yes" }
                        
              if(!($Result)) 
              {   $LoggedIn = "No login today"; $Date = "-"; $Time = "-"; $IP = "-"; }


              $LastEntry = $Result[$Result.Length-1] -split " "
              
              if($LastEntry){ 
                  # fill the variables  with the items from the log line
                  $Date = $LastEntry[1];
                  $Time = $LastEntry[2];
                  $IP   = $LastEntry[3];
              }

              [pscustomobject]@{
                "Last Seen"   = $Time;
                "IP Address"  = $IP
                "User"        = $User.UserName;
                "Logged in"   = $LoggedIn;
              }
           }

        
        # We need this for the PRTG output. It will put all logged in users into an array so we can display them in the sensor message
        $Userlist = @(); 
        $ActiveUsers = ($loggedInUsers | Where-Object -FilterScript {$_.'Logged in' -match "Yes"});
        foreach($ActiveUser in $ActiveUsers){ $Userlist += $ActiveUser.User }
    
    }

    End {
      # If we have the $prtg parameter set, the script will output data using the EXE/Script format (<value>:<message>); 
      if($Userlist.Count -eq 0)    { $UserString = "" }
      else                         { $UserString = "(" + ($Userlist -join ", ") + ")" }
      
      Write-Host ([string]::Format("{0}:{0} user(s) currently logged in {1}",$Userlist.Count,$UserString));
      $loggedInUsers | Out-GridView -Title '[PRTG] Active Users';     
      
    }    
}

This-GetUsers
