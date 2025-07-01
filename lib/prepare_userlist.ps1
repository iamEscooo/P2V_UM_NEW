param(
  [string]$ufile = Join-Path $PSScriptRoot "..\P2V_UM_data\GoLivePrep\user-masterlist_final.csv",
  [string]$pfile = Join-Path $PSScriptRoot "..\P2V_UM_data\GoLivePrep\SNOW-profiles.csv",
  [bool]$deactivate=$False,
  [bool]$checkOnly = $False
)
#-------------------------------------------------
$My_name=[io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
$My_path=Split-Path $($MyInvocation.MyCommand.Path)
if (!$workdir) {$workdir=$My_Path}
. "$workdir\P2V_include.ps1"

$output_path = $output_path_base + "\$My_name"
$outfile=$output_path+"\list_UP.csv"
#-------------------------------------------------
P2V_header -app $My_name -path $My_path 
createdir_ifnotexists($output_path)
Delete-ExistingFile -file  $outfile
#-------------------------------------------------

$profile="profile.Economics.local"
$profiles = import-csv -path $pfile

$my_userlist = @{}
$profiles=@{}
$uprofile=@{}
$ucount=0

if (Test-Path $ufile) 
    {
	 #import-csv -path $ufile -Encoding UTF8|% {$my_userlist["$($_.xkey)"]=$_;$ucount++}
	 $my_userlist=import-csv -path $ufile -Encoding UTF8
    }

if (Test-Path $pfile)
{
    $profiles=import-csv -path $pfile -Encoding UTF8
}

Add-Content -Path $outfile -Value 'Xkey,LogonID,Profile,IDM'
$count_ug=0
$count_u=0
$count_s=0
foreach ($entry in $my_userlist)
{
 #   write-host -nonewline -ForegroundColor yellow "[$($entry.xkey):$($entry.name)] "
   #$uprofile= get_AD_user -searchstring $($entry.xkey)

   If (($($entry.Deactivated -ne "TRUE") -and ($($entry.'Production System') -like "x")))
   {   
     $count_u++
     foreach ($p in $profiles)
     {
       $pp=$p.Profile
	   $pi=$p.IDM
       #"($($entry.$pp)"
     
	   
       if (($entry.$pp)  )
	   {
         "$($entry.xkey),$($entry.logonID),$pp,$pi"	   | Out-File $outfile  -Encoding "UTF8" -Append
	    $count_ug++
		if ($count_ug %10 -eq 0){write-host -nonewline ($form1 -f ("[{0,5}] exporting ..." -f $count_ug))"`r"}
	  }
     }	 
	} else 
	{ 
	  $count_s++
	  $form1 -f "skipping deactivated user $($entry.logonID)"
	}
	
     out-host
 }
 $form2 -f ("[{0,5}]" -f $count_u),"users processed"
 $form2 -f ("[{0,5}]" -f $count_s),"deactivated users skipped"
 $form2 -f ("[{0,5}]" -f $count_ug),"user-workgroup assignments exported"

 $form1 -f "output: $outfile"
P2V_footer -app $My_name
