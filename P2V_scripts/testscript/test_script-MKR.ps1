
# outPath is defaulting to script route but should be shared UNC path. Example "\\lonqasql02\ClusteredShared\Default\PlanningSpace Economics"
# writeBuffer is defaulting PS WriteBuffer = 2 * 1024 * 1024 size :StreamWriter default is 4096
# fileSize is defaulting to 50MB. Will write to files and try not to exceed this size but if input file takes it over size before last check it will exceed.
# inputFile should be supplied with script, with example of PS RS project variables file, whihc is approx 1.5MB. Can be any type of file with lines, preferrably less than overall test file size.

#  $outpath=\\somvat202005\PPS_cluster\IPS_UPDATE_shared
#  $outpath=\\tsomvat502104\IPS_UPDATE_shared\


Param(
#                $outPath = "\\tsomvat502104\IPS_share_2",
				$outPath = "\\somvat202005\PPS_cluster\IPS20_PROD",
                $writeBuffer = 2 * 1024 * 1024,
                $fileSize = 50MB,
                $inputFile = "\\somvat202005\PPS_share\P2V_scripts\testscript\logs\rs_var_in.txt",
				$tmax= 20,
				$wait= 0,
				$wait_on_error=0,
				$log= $true
)
$user=$env:UserDomain+"/"+$env:UserName
$client=$env:ComputerName
$startdate=get-date
$logFile = "\\somvat202005\PPS_share\P2V_scripts\testscript\logs\$($client).log"   #  |tee -FilePath $logFile -Append  |out-host
">------------------------  start at $startdate on $client ------------------------<" |tee -FilePath $logFile -Append  |out-host

# check input file exist - if not exit
if (![System.IO.File]::Exists($inputFile)){
                Write-Error "Input file $inputFile does not exist."
                Exit
}
# check output path exist - if not exit
if (![System.IO.Directory]::Exists($outPath)){
                Write-Error "Output path $outPath does not exist."
                Exit
}

# read example variable lines from input file into array
[string[]]$varArray = Get-Content -Path $inputFile
$t=0
$err_c=0
#Write-Host -ForegroundColor green "------> start: $t  ERR: $err_c "
"------> start: $t  ERR: $err_c "|tee -FilePath $logFile -Append|Write-Host -ForegroundColor green
$t++
while ($t -le $tmax) {
#while ($true){


    
	
    #$fileName = "RSVarTestFile_$(Get-Random).txt"
	$fileID="$($client)_$(Get-Random)"
	$fileID="$($client)--TEST"
	$fileName = "RSVarTestFile_$($fileID)_$($t).txt"
    $outputFile = Join-Path $outPath $fileName
	
                
    # Create the file
    $file = New-Item -ItemType File -Path $outputFile

                try
                {
                                $tempFileSize = 0
                                $writerCounter = 0;
                                
                                # loop - write file until size limit  
                                while ($tempFileSize -lt $fileSize)
                                {
                                                $writerCounter++
                                                
                                                try{
                                                                # create stream writer - append to file
																if ($wait -ne 0 ) {Start-Sleep -Milliseconds $wait }
																$streamWriter = [System.IO.StreamWriter]::new($outputFile, $true, [System.Text.Encoding]::UTF8, $writeBuffer)
                                                                
                                                                # loop variable array
                                                                foreach ($varLine in $varArray)
                                                                {
                                                                                # write to stream
                                                                                $streamWriter.WriteLine($varLine)
                                                                }
                                                }
												catch {
																"An error occurred: ($outputFile) - [iteration: $t writercounter: $writerCounter]"|tee -FilePath $logFile -Append
																#Write-Host "<$varline>"
																#Write-Host $_.ScriptStackTrace
																#Write-error "$_"
																"$_"|write-error
																$err_c++
															#	pause
															<# 	if ((Test-Path -Path $outputFile) -eq $false) {
																		Write-Warning "File or directory does not exist."       
															    }
																else {
																	#	 $LockingProcess = CMD /C "openfile /query /fo table"
																	#     Write-Host $LockingProcess
																	 }
																 #>
																 $streamWriter.Dispose()
																if ($wait_on_error -ne 0 ) {Start-Sleep -Milliseconds $wait_on_error}
																
												}

                                                finally
                                                {
                                                                # dispose of stream
                                                                $streamWriter.Dispose()
                                                }
                                                
                                                # write file write progress to console
                                                $tempFileSize = $(Get-Item $outputFile).Length
                                                Write-Progress -CurrentOperation "Writing to file $file" ( "Iteration: $t Counter: $writerCounter. File Size: $tempFileSize of $fileSize" )
                                }
                }
                finally
                {
                                # Delete the file after reaching the desired size
                                Remove-Item $outputFile
                }
				Write-Host -ForegroundColor green "------> T: $t  ERR: $err_c  writecounter: $writerCounter"
				"------> T: $t  ERR: $err_c  writecounter: $writerCounter"|out-file -FilePath $logFile -Append
				$t++
}

$enddate=get-date

"<-- report user [$user] on [$client] -->
inputfile          : $inputFile
outputpath         : $outPath
writebuffer        : $writeBuffer
filesize           : $fileSize
# iterations       : $tmax
waiting cycle  (ms): $wait
wait at error  (ms): $wait_on_error
# errors           : $err_c
started at         : $startdate
finished at        : $enddate
duration           : $($enddate - $startdate)
"|tee -FilePath $logFile -Append|out-host

">------------------------  finished at $enddate on $client ------------------------<" |tee -FilePath $logFile -Append  |out-host
pause