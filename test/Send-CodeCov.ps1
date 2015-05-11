#.Synopsis
#   Send Pester CodeCoverage to CodeCov.io
#.Example
#   Invoke-Gherkin -Passthru | Send-CodeCov
#.Notes
# Original from https://github.com/TravisEz13/PoshBuildTools 
# MIT License
param(
    # The CodeCoverage report from Pester (accepts pipeline input)
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    $CodeCoverage,

    [String]$RepositoryRoot = $Pwd,

    [String]$OutputPath = $Pwd,
    
    [ValidateSet('ascii','utf8')]
    $Encoding = 'ascii',

    [ValidateNotNullOrEmpty()]
    [String]$Token,

    [ValidateNotNullOrEmpty()]
    [String]$Branch = ${env:APPVEYOR_REPO_BRANCH},

    [ValidateNotNullOrEmpty()]
    [String]$JobId = ${ENV:APPVEYOR_BUILD_NUMBER}
)
process {
    Write-Verbose -Verbose "RepositoryRoot: $RepositoryRoot"
    $RepositoryRoot = $RepositoryRoot.Trim('/','\') + '\'

    $files = @()
    foreach($file in ($CodeCoverage.missedCommands | Select-Object file))
    {
        if($files -notcontains $file.file)
        {
            $files += $file.file
        }
    }
    foreach($file in ($CodeCoverage.hitCommands | Select-Object file))
    {
        if($files -notcontains $file.file)
        {
            $files += $file.file
        }
    }
    
    $fileLookup=@{}
    $fileLines =@{}

    foreach($command in $CodeCoverage.MissedCommands)
    {
        $fileKey = $command.File.replace($RepositoryRoot,'').replace('\','/')
        if(!$fileLookup.ContainsKey($fileKey))
        {
            Write-Verbose -Verbose "fileKey: $fileKey"
            $fileLookup.Add($fileKey,$command.File)
        }
        # $fileKey = $command.File
        if(!$fileLines.ContainsKey($fileKey))
        {
            $fileLines.add($fileKey, @{misses=@{}})
        }
        
        $lines = $fileLines.($fileKey).misses

        $lineKey = $($command.line)
        if(!$lines.ContainsKey($lineKey))
        {
            $lines.Add($lineKey,1)
        }
        else
        {
            $lines.$lineKey ++
        }
    }
    foreach($command in $CodeCoverage.HitCommands)
    {
        $fileKey = $command.File.replace($RepositoryRoot,'').replace('\','/')
        if(!$fileLookup.ContainsKey($fileKey))
        {
            Write-Verbose -Verbose "fileKey: $fileKey"
            $fileLookup.Add($fileKey,$command.File)
        }

         if(!$fileLines.ContainsKey($fileKey))
        {
            $fileLines.add($fileKey, @{hits=@{}})
        }
        if(!$fileLines.$fileKey.ContainsKey('hits'))
        {
            $fileLines.$fileKey.Add('hits',@{})
        }
        $lines = $fileLines.($fileKey).hits

        $lineKey = $($command.line)
        if(!$lines.ContainsKey($lineKey))
        {
            $lines.Add($lineKey,1)
        }
        else
        {
            $lines.$lineKey ++
        }
    }

    $resultLineData =@{}
    $resultMessages =@{}
    $result = @{coverage =$resultLineData
                messages = $resultMessages}
    foreach($file in $fileLines.Keys)
    {
        $hit = 0
        $partial = 0
        $missed = 0
        Write-Verbose "summarizing for file: $file" -Verbose
        $hits = @{}
        if($fileLines.$file.ContainsKey('hits'))
        {
            $hits = $fileLines.$file.hits
        }

        $misses = @{}
        if($fileLines.$file.ContainsKey('misses'))
        {
            $misses = $fileLines.$file.misses
        }

        Write-Verbose "fileKeys: $($fileLines.$file.Keys)" -Verbose
        $max = $hits.Keys| Sort-Object -Descending | Select-Object -First 1
        $maxMissLine = $misses.Keys| Sort-Object -Descending | Select-Object -First 1
        if($maxMissLine -gt $max)
        {
            $max = $maxMissLine
        }

        $lineData=@()
        $messages = @{}
        # start at line 0 per codecov docs
        for($lineNumber=0;$lineNumber -le $max;$lineNumber++)
        {
            $hitInfo = $null
            $missInfo = $null
            if($hits.ContainsKey($lineNumber))
            {
                Write-Verbose "Got cc hit at $lineNumber"
                $hitInfo = $hits.$lineNumber
            }
            if($misses.ContainsKey($lineNumber))
            {
                Write-Verbose "Got cc miss at $lineNumber"
                $missInfo = $misses.$lineNumber
            }
            
            if(!$missInfo -and !$hitInfo)
            {
                # If I put an actual null in an array ConvertTo-Json just leaves it out
                # I'll put this string in and clean it up later.
                $lineData += '!null!'
            }
            elseif($missInfo -and $hitInfo )
            {
                $lineData += "$hitInfo/$($hitInfo+$missInfo)"
            }
            elseif(!$missInfo -or $missInfo -eq 0)
            {
                $lineData += $hitInfo
            }
            else
            {
                $lineData += 0
            }
        }

        $resultLineData.Add($file,$lineData)
        $resultMessages.add($file,$messages)
    }

    $commitOutput = @(&git.exe log -1 --pretty=format:%H)
    $commit = $commitOutput[0] 

    Write-Verbose "Branch: $branch"
    Write-Verbose "JobId: $JobId"
    
    $json =$result | ConvertTo-Json
    Write-Verbose "Encoding output using: $Encoding" -Verbose
    $json = $json.Replace('"!null!"','null') 
    $json | out-file $OutputPath\CodeCov.json
    if($token) {
        $jsonPostUri = "https://codecov.io/upload/v1?token=$token&commit=$commit&branch=$branch&travis_job_id=$jobId"
        Invoke-RestMethod -Method Post -Uri $jsonPostUri -Body $json -ContentType 'application/json'
    }
}