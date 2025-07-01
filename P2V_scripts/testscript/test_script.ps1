
# outPath is defaulting to script route but should be shared UNC path. Example "\\lonqasql02\ClusteredShared\Default\PlanningSpace Economics"
# writeBuffer is defaulting PS WriteBuffer = 2 * 1024 * 1024 size :StreamWriter default is 4096
# fileSize is defaulting to 50MB. Will write to files and try not to exceed this size but if input file takes it over size before last check it will exceed.
# inputFile should be supplied with script, with example of PS RS project variables file, whihc is approx 1.5MB. Can be any type of file with lines, preferrably less than overall test file size.

Param(
    $outPath = "$PSScriptRoot",
                $writeBuffer = 2 * 1024 * 1024,
                $fileSize = 50MB,
                $inputFile = "$PSScriptRoot\rs_var_in.txt"
)

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
#$t=0
#while ($t -le 10) {
while ($true){
#$t++
    $fileName = "RSVarTestFile_$(Get-Random).txt"
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
                                                                $streamWriter = [System.IO.StreamWriter]::new($outputFile, $true, [System.Text.Encoding]::UTF8, $writeBuffer)
                                                                
                                                                # loop variable array
                                                                foreach ($varLine in $varArray)
                                                                {
                                                                                # write to stream
                                                                                $streamWriter.WriteLine($varLine)
                                                                }
                                                }
                                                finally
                                                {
                                                                # dispose of stream
                                                                $streamWriter.Dispose()
                                                }
                                                
                                                # write file write progress to console
                                                $tempFileSize = $(Get-Item $outputFile).Length
                                                Write-Progress -CurrentOperation "Writing to file $file" ( "Counter: $writerCounter. File Size: $tempFileSize of $fileSize" )
                                }
                }
                finally
                {
                                # Delete the file after reaching the desired size
                                Remove-Item $outputFile
                }
}

