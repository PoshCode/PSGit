# try {
#     $IsWindows = [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform( [Runtime.InteropServices.OSPlatform]::Windows )
#     $IsLinux = [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform( [RUntime.InteropServices.OSPlatform]::Linux )
#     $IsOSX = [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform( [RUntime.InteropServices.OSPlatform]::OSX )
# } catch {}
# $Arch = "-" + [Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
enum Part {
    Major
    Minor
    Build
    Revision
    None
}

# Add-Type -Path (Join-Path (Join-Path $PSScriptRoot NativeBinaries\$runtime)
${;} = [System.IO.Path]::PathSeparator
switch -Wildcard (Get-ChildItem -Path "$PSScriptRoot\lib\NativeBinaries\*\native" -Recurse -Filter '*git2-6311e88.*') {
    "*.so"   { $env:LD_LIBRARY_PATH = "" + $_.Directory + ${;} + $Env:LD_LIBRARY_PATH }
    "*.dll"  { $env:PATH = "" + $_.Directory + ${;} + $Env:PATH }
    "*.dyld" { $env:DYLD_LIBRARY_PATH = "" + $_.Directory + ${;} + $Env:DYLD_LIBRARY_PATH }
}


# Internal Functions
#region Interal Functions
function WriteMessage {
    [CmdletBinding()]
    param (
        # The Type of message you'd like, its just a prefix to the message.
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        $Type,

        # The message to display
        [Parameter(Mandatory=$true,Position=1)]
        [string]
        $Message,

        # Color of the message, it will default to the hosts' verbose color.
        [Parameter(Position=2)]
        [PoshCode.Pansies.RgbColor]
        $ForegroundColor = ($host.PrivateData.VerboseForegroundColor|ConvertColor),
        # Background color of the message, it will default to the hosts' verbose color.
        [Parameter(Position=3)]
        [PoshCode.Pansies.RgbColor]
        $BackgroundColor = ($host.PrivateData.VerboseBackgroundColor|ConvertColor -default "black")
    )

    #todo check to see if the preference is on or off

    Write-Host "$($Type.ToUpper()): $Message" -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
}

function ConvertColor {
    #.Synopsis
    #   A color converter that handles WPF colors
    #.Description
    #   ConvertColor exists specifically to handle the WPF colors that ISE uses as it's defaults
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        $color,
        $default="yellow"
    )
    if($color -is [string] -and $color.Length -gt 7) {
        if($color -match "#00[0-9A-F]{6}") {
            $color = if($host.PrivateData.ConsolePaneBackgroundColor) {
                $host.PrivateData.ConsolePaneBackgroundColor
            } else {
                $host.UI.RawUI.BackgroundColor
            }
        }
        if("System.Windows.Media.Color" -as [type]) {
            #if its a transparent color, just use the background color of the host
            $color = "#" + ([System.Windows.Media.Color]"$color").ToString().Substring(3)
        } elseif("$color"[0] -eq "#") {
            $color = "#" + "$color".SubString($color.Length - 6)
        }
    }

    if(($color -as [PoshCode.Pansies.RgbColor]) -ne $null) {
        ([PoshCode.Pansies.RgbColor]$color).ConsoleColor
    } else {
         ([PoshCode.Pansies.RgbColor]$default).ConsoleColor
    }
}
#endregion

function Get-RootFolder {
    #.Synopsis
    #   Search up the directory tree recursively for a git root (and corresponding .git folder)
    [CmdletBinding(DefaultParameterSetName="IndexAndWorkDir")]
    param (
        # Where to start searching
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Root = $Pwd
    )
    end {
        # Git Repositories are File System Based, and don't care aabout PSDrives
        [LibGit2Sharp.Repository]::Discover((Convert-Path $Root))
    }
}

# TODO: DOCUMENT ME
function Get-Change {
    [CmdletBinding(DefaultParameterSetName="IndexAndWorkDir")]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Root = $Pwd,

        [Parameter(Position = 0)]
        [String[]]$PathSpec,

        [Parameter(ParameterSetName="WorkDirOnly", Mandatory=$true)]
        [Switch]$UnStagedOnly,

        [Parameter(ParameterSetName="IndexOnly", Mandatory=$true)]
        [Switch]$StagedOnly,

        [Parameter()]
        [switch]
        $HideUntracked,

        [Parameter()]
        [switch]
        $HideSubmodules,

        [Parameter()]
        [switch]
        $ShowIgnored
    )
    end {
        $Path = [LibGit2Sharp.Repository]::Discover((Convert-Path $Root))
        if(!$Path) {
            Write-Warning "The path is not in a git repository!"
            return
        }

        $PathSpec = $PathSpec | Where { "$_".Trim().Length -gt 0 }

        try {
            $repo = New-Object LibGit2Sharp.Repository $Path
            $Path = $repo.Info.WorkingDirectory

            $Options = New-Object LibGit2Sharp.StatusOptions
            $Options.Show = $PSCmdlet.ParameterSetName
            # Don't touch PathSpec unless you're serious, it breaks the output
            if($PathSpec) { $Options.PathSpec = $PathSpec }
            $Options.DetectRenamesInWorkDir = $true
            if($HideSubmodules)
            {
                $Options.ExcludeSubmodules = $true
            }

            $status = $repo.RetrieveStatus($Options)
        } finally {
            $repo.Dispose()
        }

        # Unaltered, Added, Staged, Removed, RenamedInIndex, StagedTypeChange,
        # Untracked, Modified, Missing, TypeChanged, RenamedInWorkDir,
        # Unreadable, Ignored, Nonexistent

        # Output staged changes, if any
        foreach($file in $status.Added) {
            New-Object PSCustomObject -Property @{
                PSTypeName = "PSGit.FileStatus"
                Staged = $true
                Change = "Added"
                Path = $file.FilePath + $(if(Test-Path (Join-Path $Path $File.FilePath) -Type Container){ "\" })
            }
        }
        foreach($file in $status.RenamedInIndex) {
            New-Object PSCustomObject -Property @{
                PSTypeName = "PSGit.FileStatus"
                Staged = $true
                Change = "Renamed"
                Path = $file.FilePath + $(if(Test-Path (Join-Path $Path $File.FilePath) -Type Container){ "\" })
                OldPath = $File.HeadToIndexRenameDetails.OldFilePath + $(if(Test-Path (Join-Path $Path $File.HeadToIndexRenameDetails.OldFilePath) -Type Container){ "\" })
            }
        }
        foreach($file in $status.Removed) {
            New-Object PSCustomObject -Property @{
                PSTypeName = "PSGit.FileStatus"
                Staged = $true
                Change = "Removed"
                Path = $file.FilePath + $(if(Test-Path (Join-Path $Path $File.FilePath) -Type Container){ "\" })
            }
        }
        foreach($file in $status.Staged) {
            #BUGBUG: hides rename + edit, but avoids double-outputs (and behaves like git)
            if(($file.State -band [LibGit2Sharp.FileStatus]::RenamedInIndex) -eq 0) {
                New-Object PSCustomObject -Property @{
                    PSTypeName = "PSGit.FileStatus"
                    Staged = $true
                    Change = "Modified"
                    Path = $file.FilePath + $(if(Test-Path (Join-Path $Path $File.FilePath) -Type Container){ "\" })
                }
            }
        }
        # Output unstaged changes, if any
        foreach($file in $status.RenamedInWorkDir) {
            New-Object PSCustomObject -Property @{
                PSTypeName = "PSGit.FileStatus"
                Staged = $false
                Change = "Renamed"
                Path = $file.FilePath + $(if(Test-Path (Join-Path $Path $File.FilePath) -Type Container){ "\" })
                OldPath = $File.IndexToWorkDirRenameDetails.OldFilePath + $(if(Test-Path (Join-Path $Path $File.IndexToWorkDirRenameDetails.OldFilePath) -Type Container){ "\" })
            }
        }
        foreach($file in $status.Modified) {
            #BUGBUG: hides rename + edit, but avoids double-outputs (and behaves like git)
            if(($file.State -band [LibGit2Sharp.FileStatus]::RenamedInWorkDir) -eq 0) {
                New-Object PSCustomObject -Property @{
                    PSTypeName = "PSGit.FileStatus"
                    Staged = $false
                    Change = "Modified"
                    Path = $file.FilePath + $(if(Test-Path (Join-Path $Path $File.FilePath) -Type Container){ "\" })
                }
            }
        }
        foreach($file in $status.Missing) {
            New-Object PSCustomObject -Property @{
                PSTypeName = "PSGit.FileStatus"
                Staged = $false
                Change = "Removed"
                Path = $file.FilePath + $(if(Test-Path (Join-Path $Path $File.FilePath) -Type Container){ "\" })
            }
        }
        # Optional output
        if(!$HideUntracked) {
            foreach($file in $status.Untracked) {
                New-Object PSCustomObject -Property @{
                    PSTypeName = "PSGit.FileStatus"
                    Staged = $false
                    Change = "Added"
                    Path = $file.FilePath + $(if(Test-Path (Join-Path $Path $File.FilePath) -Type Container){ "\" })
                }
            }
        }
        if($ShowIgnored) {
            foreach($file in $status.Ignored) {
                New-Object PSCustomObject -Property @{
                    PSTypeName = "PSGit.FileStatus"
                    Staged = $false
                    Change = "Ignored"
                    Path = $file.FilePath + $(if(Test-Path (Join-Path $Path $File.FilePath) -Type Container){ "\" })
                }
            }
        }
    }
}

$BranchProperties =
    "FriendlyName",
    @{ Name="Tip";      Expr = { $_.Tip.Sha}},
    @{ Name="IsHead";   Expr = { $_.IsCurrentRepositoryHead}},
    "CanonicalName", "IsRemote", "IsTracking",
    @{ Name="IsMerged"; Expr = { $False }},
    @{ Name="Parent"; Expr = { $null }},
    # This got more expensive in LibGit2Sharp 0.25
    # Might be easier to use RemoteName, but to maintain compatibility:
    @{ Name="Remote";   Expr = { $_.Repository.Network.Remotes[$_.RemoteName].Url }},
    @{ Name="Ahead";    Expr = { $_.TrackingDetails.AheadBy }},
    @{ Name="Behind";   Expr = { $_.TrackingDetails.BehindBy }},
    @{ Name="CommonAncestor"; Expr = { $_.TrackingDetails.CommonAncestor.Sha }},
    @{ Name="GitDir";   Expr = { $_.Repository.Info.WorkingDirectory}}

$CommitProperties =
    @{Name = "Sha";     Expr = { $_.Id.Sha }},
    @{Name = "Branch";  Expr = { $c = $_; @($c.Repository.Branches).Where({$c.Sha -in $_.Tip.Sha},1)[0]}},
    @{Name = "Tags";    Expr = { $c = $_; @($c.Repository.Tags).Where({$c.Sha -eq $_.Target.Sha})}},
    "Parents", "Author", "IsHead",
    @{Name = "Date";    Expr = { $_.Author.When}},
    "MessageShort", "Message"

$Config = DATA {
    @{
        Branches = @{
            master = @{
                Pattern = "master"
                # Matches tags like v1.0.0 or 2.1.0.0
                VersionTag      = "v?(?<version>\d+\.\d+\.\d+(?:\d+\.)?)"
                NewIncrement    = "Minor"
                CommitIncrement = "Build"
            }
            release = @{
                Pattern = "releases?/"
                # Matches release branches like 1.0.0
                VersionName     = "releases?/(?<version>\d+\.\d+\.\d+)"
                # NOTIMPLEMENTED: VersionTag      = "v?(?<version>\d+\.\d+\.\d+(?:\d+\.)?)"
                NewIncrement    = "Minor"
                CommitIncrement = "None"
            }
            feature = @{
                Pattern = "features?/|dev/"
                NewIncrement = "Build"
                CommitIncrement = "Revision"
            }
        }
    }
}

# TODO: DOCUMENT ME
function Get-Info {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Root = $Pwd
    )
    end {
        $Path = [LibGit2Sharp.Repository]::Discover((Convert-Path $Root))
        if(!$Path) {
            Write-Warning "The path is not in a git repository!"
            return
        }

        try {
            $repo = New-Object LibGit2Sharp.Repository $Path

            # We have to transform the object to keep the data around after .Dispose()
            $repo.Head |
                Select-Object $BranchProperties |
                ForEach-Object { $_.PSTypeNames.Insert(0,"PSGit.Branch"); $_ }
        } finally {
            if($null -ne $repo) {
                $repo.Dispose()
            }
        }
    }
}

# TODO: DOCUMENT ME
function Get-Branch {
    [Alias("branch")]
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Root = $Pwd,

        [Switch]$Force
    )
    end {
        $Path = [LibGit2Sharp.Repository]::Discover((Convert-Path $Root))
        if(!$Path) {
            Write-Warning "The path is not in a git repository!"
            return
        }

         try {
            $repo = New-Object LibGit2Sharp.Repository $Path
            GetBranch $repo
        } finally {
            if($null -ne $repo) {
                $repo.Dispose()
            }
        }
    }
}

function GetBranch($repo) {
    #.Synopsis
    #    get branches from existing repo object
    $(
        # In the initialized state, there are no "Branches"
        if([Linq.Enumerable]::Count($repo.Branches) -eq 0) {
            # But really, there is the master!
            $repo.Head
        } elseif($Force) {
            $repo.Branches
        } else {
            $repo.Branches | Where-Object { !$_.IsRemote }
        }
    # We have to transform the object to keep the data around after .Dispose()
    ) | Select-Object $BranchProperties |
        ForEach-Object { $_.PSTypeNames.Insert(0,"PSGit.Branch"); $_ }
}

function Get-Status {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Root = $Pwd
    )
    Get-Info -Root $Root |
        Add-Member -Type NoteProperty -Name Changes -Value (
            Get-Change -Root $Root
        ) -Passthru

}

# TODO: DOCUMENT ME
function Show-Status {
    [Alias("Status")]
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Root = $Pwd
    )
    $status = Get-Status -Root $Root
    $changes = $status.Changes

    $status | Out-Default

    if($info.BehindBy) {
        WriteMessage "Action" "  (use `git pull` to merge the remote branch into yours)"
    }
    $staged = $changes | where { $_.Staged }
    $unstaged = $changes | where { !$_.Staged}
    $added = $unstaged | where { $_.Change -eq "Added" }
    $unstaged = $unstaged | where { $_.Change -ne "Added" }

    if($staged) {
        WriteMessage "Changes to be committed" "`n  (use ``git reset HEAD `${file}`` to unstage)" -ForegroundColor "Green"
        # $fg, $Host.UI.RawUI.ForegroundColor = $Host.UI.RawUI.ForegroundColor, "Green"
        $staged | Out-Default
        # $Host.UI.RawUI.ForegroundColor = $fg
    }

    if($unstaged) {
        WriteMessage "Changes not staged for commit" "`n  (use ``git add `${file}`` to update what will be committed)`n  (use ``git checkout -- `${file}`` to discard changes in the working directory)" -ForegroundColor "DarkYellow"
        $unstaged | Out-Default
    }

    if($added) {
        WriteMessage "Untracked Files" "`n  (use ``git add `${file}`` to include them in what will be committed)" -ForegroundColor "Red"
        $added | Out-Default
    }
}

# Export-ModuleMember -Function *-* -Alias *

# TODO: DOCUMENT ME
function Get-Log {
    [Alias("Log")]
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Root = $Pwd
    )
    end {
        $Path = [LibGit2Sharp.Repository]::Discover((Convert-Path $Root))
        if (!$Path) {
            Write-Warning "The path is not in a git repository!"
            return
        }
        try {
            $repo = New-Object LibGit2Sharp.Repository $Path

            # We have to transform the object to keep the data around after .Dispose()
            $script:Branches = GetBranch $repo

            # Figure out where all the branches start ...
            $master = $script:Branches.Where({$_.FriendlyName -match $Config.Branches["master"].Pattern}, 1)[0]

            # Because numbering is based on Master, get all of master:
            $masterLog = $repo.Commits.QueryBy(@{
                SortBy = "Topological,Time"
                IncludeReachableFrom = $master.FriendlyName
                FirstParentOnly = $true
            }) | Select-Object $CommitProperties

            # TODO: implement paging so we don't return all of this every time ...
            $Log = $repo.Commits.QueryBy(@{
                SortBy = "Topological,Time"
            }) | Select-Object $CommitProperties |
                 ForEach-Object { $_.PSTypeNames.Insert(0, "PSGit.Commit"), $_ }

            foreach($commit in $masterLog) {
                if($actual = $Log.Where({$commit.Sha -eq $_.Sha }, 1)[0]) {
                    Write-Verbose "Set $($master.FriendlyName) branch on $($actual.Sha) ($($actual.MessageShort))"
                    $actual.Branch = $master
                    if($actual.Sha -eq $master.Tip.Sha) {
                        $master.Tip = $actual
                    }
                }
            }

            # Determine which branch the tip is in, if possible
            if (!$Log[0].Branch) {
                foreach($branch in $script:Branches -ne $master) {
                    if ($Log[0].Sha -in $repo.Commits.QueryBy(@{SortBy = "Topological,Time"; IncludeReachableFrom = $branch.FriendlyName}).Sha) {
                        $Log[0].Branch = $branch
                        break
                    }
                }
            }

            # We need to fix:
            # - only the tips of each branch have branch data
            # - the parent commit objects are separate (but identical) objects
            foreach ($commit in $Log) {
                Write-Verbose "Commit $($commit.Sha) ($($commit.MessageShort)) Branch: $($commit.Branch.FriendlyName)"
                # Reset the "Parents" to be pointers to their representation in the Log
                $commit.Parents = $Log.Where{$_.Sha -in $commit.Parents.Id}
                # Set the branch on all the parents
                foreach ($parent in $commit.Parents) {
                    # The first parent is the true parent
                    if (!$parent.Branch) {
                        Write-Verbose "Set branch on $($parent.Sha) ($($parent.MessageShort))"
                        $parent.Branch = $commit.Branch
                    } else {
                        # Fix initial assignment from Select-Object
                        if(!$parent.Branch.PSTypeNames.Contains("PSGit.Branch")) {
                            Write-Verbose "Update branch on $($parent.Sha) ($($parent.MessageShort))"
                            $parent.Branch = $script:Branches.Where({ $_.CanonicalName -eq $parent.Branch.CanonicalName },1)[0]
                        }
                        # Mark parent merged
                        if (@($commit.Parents).Count -gt 1 -and $commit.Branch.CanonicalName -ne $parent.Branch.CanonicalName) {
                            Write-Verbose ($parent.Branch.FriendlyName + " was merged into " + $commit.Branch.FriendlyName)
                            $parent.Branch.IsMerged = $true
                        }
                    }
                }
            }

            # TODO: for versioning purposes, it would be nice to know which commits have branches from them ...
            $Log
            # Add-Member -Input $Log -Type NoteProperty -Name Branches -Value $script:Branches -Passthru
        } finally {
            if($null -ne $repo) {
                $repo.Dispose()
            }
        }
    }
}

# TODO: DOCUMENT ME

function Get-Version {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Root = $Pwd,
        [String]$Sha
    )
    begin {
        [Part]$script:HighestPartIncremented = "None"
        [Version]$BaseVersion = "0.0.0.0"
        $Increment = [Ordered]@{
            Major = 0
            Minor = 0
            Build = 0
            Revision = 0
            None = 0 # this is a hack
        }
        function PushIncrement {
            [CmdletBinding()]
            param($Increment, $Commit, [Part]$NewIncrement, [Part]$CommitIncrement, [Parameter(ValueFromRemainingArguments)]$Args)

            # We only increment one part per commit, so pick the highest one we're going to use
            if ($Commit.Parents -eq $null -or $Commit.Parents.Version -or -not (@($Commit.Parents).Branch.CanonicalName -eq $Commit.Branch.CanonicalName)) {
                Write-Verbose "Increment $NewIncrement or $CommitIncrement"
                [Part]$CommitIncrement = [Math]::Min([int]$NewIncrement, [int]$CommitIncrement)
            }
            # But only increment if we're not past that already
            if ($CommitIncrement -le $script:HighestPartIncremented) {
                Write-Verbose "Increment $CommitIncrement for '$($Commit.MessageShort)' (on $($Commit.Branch.FriendlyName)) $($Commit.Sha.Substring(0,7))"
                $script:HighestPartIncremented = $CommitIncrement
                $Increment["$CommitIncrement"] += 1
            } else {
                Write-Verbose "Skip incrementing $CommitIncrement because we already incremented $script:HighestPartIncremented"
            }
        }
        function GetBaseVersion {
            [CmdletBinding()]
            param($Repo, $Log, [string]$Sha)
            [Version]$BaseVersion = "0.0.0.0"

            $roots = @($repo.Branches.Where({$_.FriendlyName -match $Config.Branches["master"].Pattern}, 1)[0].FriendlyName)
            if($Sha) { $roots += $Sha }

            $global:Master = $repo.Commits.QueryBy(@{
                SortBy = "Topological,Time"
                IncludeReachableFrom = $roots
                FirstParentOnly = $true
            })

            # If Sha is specified, skip any commits after that one
            if($Sha) {
                $Master = [Linq.Enumerable]::SkipWhile( $Master, [Func[LibGit2Sharp.Commit,Bool]]{ !$args[0].Sha.StartsWith($Sha) })
            }
            # Then find the first commit in the log:
            $First = [Linq.Enumerable]::First($Master).Sha
            $Commit = $Log.Where({$_.Sha -match $First},1)[0]

            # Special case: if we're on a release branch, then the version is the release version
            # ... but we need to count how many commits there are on this branch
            if ($Commit.Branch.FriendlyName -match $Config.Branches.Release.Pattern) {
                if ($Commit.Branch.FriendlyName -match "^$($Config.Branches.Release.VersionName)") {
                    $Count = [Linq.Enumerable]::Count($repo.Commits.QueryBy(@{
                        SortBy = "Topological,Time"
                        IncludeReachableFrom = $Commit.Sha
                        ExcludeReachableFrom = $roots[0]
                        FirstParentOnly = $true
                    }))
                    [Version]$BaseVersion = $Matches["Version"] + ".$Count"

                    $Commit | Add-Member -Type NoteProperty -Name Version -Value $BaseVersion -PassThru |
                              Add-Member -Type NoteProperty -Name CommitsInBranch -Value $Count -PassThru
                    Write-Verbose "On release branch $BaseVersion on $($Commit.Sha): $($Commit.Tags.FriendlyName)"
                    return
                } else {
                    throw "Can't determine version from release branch name. Check your config for release branches "
                }
            }

            do {
                ## check if we found a source of truth:
                # Does it have a version tag:
                if ($Commit.Tags.FriendlyName -match "^$($Config.Branches.Master.VersionTag)$") {
                    [Version]$BaseVersion = $Matches["Version"]
                    $Commit | Add-Member -Type NoteProperty -Name Version -Value $BaseVersion -Passthru |
                              Add-Member -Type NoteProperty -Name CommitsInBranch -Value 0 -PassThru
                    Write-Verbose "Found version tag $BaseVersion on $($Commit.Sha): $($Commit.Tags.FriendlyName)"
                    break
                }

                # Is it a merge from a release branch:
                if ($Release = @($Commit.Parents).Where( {$_.Branch.FriendlyName -match $Config.Branches.Release.Pattern}, 1)[0]) {
                    # Check the branch name
                    if ($Release.Branch.FriendlyName -match "^$($Config.Branches.Release.VersionName)") {
                        [Version]$BaseVersion = $Matches["Version"]
                        $Release | Add-Member -Type NoteProperty -Name Version -Value $BaseVersion -Passthru |
                                   Add-Member -Type NoteProperty -Name CommitsInBranch -Value 0 -PassThru
                        Write-Verbose "Found release branch merge $BaseVersion on $($Commit.Sha) from $($Release.Sha): $($Commit.Tags.FriendlyName)"
                        break
                    } else {
                        throw "Can't determine version from release branch name. Check your config for release branches "
                    }
                }
                $Commit = @($Commit.Parents).Where( {$_.Branch.FriendlyName -match $Config.Branches.master.Pattern}, 1)[0]
            } while ($Commit)
        }
    }
    end {
        $Path = [LibGit2Sharp.Repository]::Discover((Convert-Path $Root))
        if (!$Path) {
            Write-Warning "The path is not in a git repository!"
            return
        }

        try {
            $repo = New-Object LibGit2Sharp.Repository $Path

            if (!@($repo.Commits)) {
                Write-Warning "No commits found in repository!"
                return
            }
            # In order to guarantee each branch gets it's own version number, we need to index them in "some way"
            $Log = Get-GitLog
            # Start from the specified commit or the current head
            if ($Sha) {
                $Commit = $tip = $Log.Where( { $_.Sha.StartsWith($Sha) })
                if (@($tip).Count -gt 1) {
                    throw "Bad Sha, matches multiple commits: `n$($tip.Sha -join "`n")"
                }
            } else {
                $Commit = $tip = $Log[0] #.Where{ $_.Id -eq $repo.Head.Id}
            }

            # Now, to find the version for *THIS* commit, we need to:
            # 1. Find a source of truth
            $BaseVersionCommit = GetBaseVersion $Repo $Log $Sha
            $Count = $BaseVersionCommit.CommitsInBranch

            # 2. Increment from there according to rules
            while($Commit -and $Commit.Sha -ne $BaseVersionCommit.Sha) {
                Write-Verbose "Increment for '$($Commit.MessageShort)' ($($Commit.Branch.FriendlyName)) $($Commit.Sha.Substring(0,7))"

                ## otherwise increment according to the config
                # find the branch config for this branch
                $BranchConfig = $null
                foreach ($branch in $Config.Branches.Keys) {
                    if ($Commit.Branch.FriendlyName -match "^$branch") {
                        $BranchConfig = $Config.Branches[$branch]
                        continue
                    }
                }
                if ($BranchConfig) {
                    # increment accordingly
                    . PushIncrement $Increment $Commit @BranchConfig
                } else {
                    Write-Warning "Can't find config for branch: $($Commit.Branch)"
                    $Commit | Out-Host
                }

                # When we reach the BaseVersion, stop
                if($Commit.Parents.Sha -eq $BaseVersionCommit.Sha) {
                    break
                }
                # Otherwise, follow the trail
                $Commit = @($Commit.Parents)[-1]
                $Count += 1
            }

            # $Increment | Out-String | Write-Host -Fore "#336699"
            # $BaseVersionCommit.Version | Out-String | Write-Host -Fore "#336699"

            $Version = [Version]::new(
                ($BaseVersionCommit.Version.Major + $Increment.Major),
                ($BaseVersionCommit.Version.Minor + $Increment.Minor),
                ($BaseVersionCommit.Version.Build + $Increment.Build),
                ([Math]::Max(0, $BaseVersionCommit.Version.Revision) + $Increment.Revision))

            if($Count -eq $BaseVersionCommit.CommitsInBranch) {
                $SemVer = $Version.ToString(3) + "+" + $Count + '.sha.' + $tip.Sha + '.date.' + $tip.Author.When.UtcDateTime.ToString("O").split(".", 2)[0]
            } else {
                $SemVer = $Version.ToString(3) + "-" + $tip.Branch.FriendlyName + '.' + $Version.Revision + '+' + $Increment.None + '.sha.' + $tip.Sha + '.date.' + $tip.Author.When.UtcDateTime.ToString("O").split(".", 2)[0]
            }

            [PSCustomObject]@{
                Version = $Version
                SemVer = $SemVer
            }

        } finally {
            if ($null -ne $repo) {
                $repo.Dispose()
            }
        }
    }
}

# For PSTypes??
# Update-TypeData -TypeName LibGit2Sharp.StatusEntry -MemberType ScriptMethod -MemberName ToString -Value { $this.FilePath }
# OR -Value {
#   switch($this.State){
#       "Ignored" { }
#       "Untracked" { "?? " + $this.FilePath }
#       "Added" { "A  " + $this.FilePath }
#       "Modified" { " M " + $this.FilePath}
#       "Added, Modified" { "AM " + $this.FilePath}
#       default { $this.State + " " + $this.FilePath}
#   }
# } -Force


# TODO: DOCUMENT ME
function New-Repository {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Root = $Pwd
    )
    end {
        $Path = Convert-Path $Root
        # Not sure why this is needed, but if you do a folder on the root it fails
        $Path = Join-Path $path "."

        $null = mkdir $Root -Force -ErrorAction SilentlyContinue
        try {
            $rtn = [LibGit2Sharp.Repository]::Init($Path)
        } finally {}
    }
}

. $PSScriptRoot\PSGitPrompt.ps1
. $PSScriptRoot\PSGitPowerline.ps1
