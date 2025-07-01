# outPath is defaulting to script route but should be shared UNC path. Example "\\lonqasql02\ClusteredShared\Default\PlanningSpace Economics"
# writeBuffer is defaulting PS WriteBuffer = 2 * 1024 * 1024 size :StreamWriter default is 4096
# fileSize is defaulting to 50MB. Will write to files and try not to exceed this size but if input file takes it over size before last check it will exceed.
# inputFile should be supplied with script, with example of PS RS project variables file - approx 1.5MB. Can be any type of file with lines, preferrably less than overall test file size.
# writeRetryLimit is the number of times attempt to get a lock on output file if used by another process. default to 10 times/
# retryWaitInSeconds is delay between each retry. default to 1 seconds between tries

Param(
    $outPath = "$PSScriptRoot",
	$writeBuffer = 2 * 1024 * 1024,
	$fileSize = 50MB,
	$inputFile = "$PSScriptRoot\rs_var_in.txt",
	$writeRetryLimit = 10,
	$retryWaitInSeconds = 1
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

while ($true) {
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
			$writerCounterCheck = $writerCounter
			
			# retry x number of times if we cannot get write lock on file
			for ($iWriteTry = 1; $iWriteTry -le $writeRetryLimit; $iWriteTry++)
			{
				$hasWriteLock = $false

				try
				{
					# create stream writer - append to file
					$streamWriter = [System.IO.StreamWriter]::new($outputFile, $true, [System.Text.Encoding]::UTF8, $writeBuffer)
					$hasWriteLock = $true

					# loop variable array
					foreach ($varLine in $varArray)
					{
						# write to stream
						$streamWriter.WriteLine($varLine)
					}
					
					# increment counter of successful write to file
					$writerCounter++
				}
				catch [System.IO.IOException]
				{
					# expected error granting a file handle. if we already have the handle or reached retry limit output error and break
					if ($hasWriteLock -eq $true -or $iWriteTry -eq $writeRetryLimit)
					{
						Write-Error $_
						break;
					}
					
					#otherwise we can retry after x seconds
					Write-Progress -CurrentOperation "Writing to file $file" ( "Failed! Attempt $iWriteTry of $writeRetryLimit")
					Write-output -CurrentOperation "Writing to file $file" ( "Failed! Attempt $iWriteTry of $writeRetryLimit")
					Start-Sleep -Seconds $retryWaitInSeconds
					continue
				}
				catch
				{
					# not sure what the error is here. output error and break
					Write-Error $_
					break
				}
				finally
				{
					# Write-Warning "Closed $outputFile."
					# dispose of stream
					$streamWriter.Dispose()
				}
			}	
			
			# if we have not written the variables to the file we stop trying here
			if ($writerCounterCheck -eq $writerCounter){
				Write-Error "Failed to write variables to $file"
				break
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
