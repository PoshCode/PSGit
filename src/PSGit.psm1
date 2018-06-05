# try {
#     $IsWindows = [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform( [Runtime.InteropServices.OSPlatform]::Windows )
#     $IsLinux = [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform( [RUntime.InteropServices.OSPlatform]::Linux )
#     $IsOSX = [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform( [RUntime.InteropServices.OSPlatform]::OSX )
# } catch {}
# $Arch = "-" + [Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture

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
    @{ Name="IsHead";   Expr = { $_.IsCurrentRepositoryHead}},
    "CanonicalName", "FriendlyName", "IsRemote", "IsTracking",
    @{ Name="Tip";      Expr = { $_.Tip.Sha}},
    # This got more expensive in LibGit2Sharp 0.25
    # Might be easier to use RemoteName, but to maintain compatibility:
    @{ Name="Remote";   Expr = { $_.Repository.Network.Remotes[$_.RemoteName].Url }},
    @{ Name="Ahead";    Expr = { $_.TrackingDetails.AheadBy }},
    @{ Name="Behind";   Expr = { $_.TrackingDetails.BehindBy }},
    @{ Name="CommonAncestor"; Expr = { $_.TrackingDetails.CommonAncestor.Sha }},
    @{ Name="GitDir";   Expr = { $_.Repository.Info.WorkingDirectory}}

$CommitProperties =
    @{Name = "Sha";     Expr = { $_.Id.Sha }},
    @{Name = "Branch";  Expr = { $c = $_; $c.Repository.Branches.Where({$c.Id.Sha -in $_.Target.Sha})}},
    @{Name = "Tags";    Expr = { $c = $_; $c.Repository.Tags.Where({$c.Id.Sha -eq $_.Target.Id.Sha})}},
    "Parents", "Author", "IsHead",
    @{Name = "Date";    Expr = { $_.Author.When}},
    @{Name = "Message"; Expr = { $_.MessageShort}}

$Config = DATA {
    @{
        Branches = @{
            master = @{
                Pattern = "master"
                # Matches tags like v1.0.0 or 2.1.0.0
                VersionTag      = "v?(?<version>\d+\.\d+\.\d+(?:\d+\.)?)"
                NewIncrement    = "Major"
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
            $Branches = GetBranch $repo

            # TODO: implement paging so we don't return all of this every time ...
            $Log = $repo.Commits.QueryBy(@{SortBy = "Topological,Time"}) | Select-Object $CommitProperties |
                    Add-Member ScriptMethod ToString { $this.Sha + " (tag: $($this.Tags.FriendlyName -join ', '))" } -PassThru -Force |
                    ForEach-Object { $_.PSTypeNames.Insert(0, "PSGit.Commit"), $_ }

            # We need to fix:
            # - only the tips of each branch have branch data
            # - the parent commit objects are separate (but identical) objects
            foreach ($commit in $Log) {
                Write-Verbose "Commit $($commit.Sha) Branch: $($commit.Branch.FriendlyName)"
                # Reset the "Parents" to be pointers to their representation in the Log
                $commit.Parents = $Log.Where{$_.Sha -in $commit.Parents.Id}
                # Set the branch on all the parents
                foreach ($parent in $commit.Parents) {
                    # The first parent is the true parent
                    if (!$parent.Branch) {
                        $parent.Branch = $commit.Branch
                    } else {
                        # Fix initial assignment from Select-Object
                        if(!$parent.Branch.PSTypeNames.Contains("PSGit.Branch")) {
                            $parent.Branch = $Branches.Where{ $_.CanonicalName -eq $parent.Branch.CanonicalName }
                        }
                        # Mark parent merged
                        if (@($commit.Parents).Count -gt 1 -and $commit.Branch.CanonicalName -ne $parent.Branch.CanonicalName) {
                            Write-Verbose ($parent.Branch.FriendlyName + " was merged into " + $commit.Branch.FriendlyName)
                            $parent.Branch.IsMerged = $true
                        }
                    }
                }
            }


            # Figure out where all the branches start ...
            $master = $Branches.Where( {$_.Branch -match $Config.master.Pattern}, 1)

            # Because numbering is based on Master, get all of master:
            $masterLog = $master.Commits.QueryBy(@{SortBy = "Topological,Time"; IncludeReachableFrom = $master.FriendlyName; FirstParentOnly = $true}) |
                Select-Object $CommitProperties

            foreach($commit in $masterLog) {
                if($actual = $Log.Where({$commit.Sha -eq $_.Sha }, 1)) {
                    $actual.Branch = $master
                    if($actual.Sha -eq $Branch.Tip.Sha) {
                        $Branch.Tip = $actual
                    }
                }
            }
            # Determine which branch the tip is in, if possible
            if (!$Log[0].Branch) {
                foreach($branch in $Branches -ne $master) {
                    if ($Log[0].Sha -in $repo.Commits.QueryBy(@{SortBy = "Topological,Time"; IncludeReachableFrom = $branch.FriendlyName}).Sha) {
                        $Log[0].Branch = $branch
                        break
                    }
                }
            }
            # TODO: for versioning purposes, it would be nice to know which commits have branches from them ...

            Add-Member -Input $Log -Type NoteProperty -Name Branches -Value $Branches -Passthru
        } finally {
            if($null -ne $repo) {
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
