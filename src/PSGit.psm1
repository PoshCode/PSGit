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
        [ConsoleColor]
        $ForegroundColor = ($host.PrivateData.VerboseForegroundColor|ConvertColor),
        # Background color of the message, it will default to the hosts' verbose color.
        [Parameter(Position=3)]
        [ConsoleColor]
        $BackgroundColor = ($host.PrivateData.VerboseBackgroundColor|ConvertColor -default "black")
    )

    #todo check to see if the preference is on or off

    Write-Host "$($Type.ToUpper()): $Message" -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
}

function ConvertColor {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        $color,
        $default="yellow"
    )
    if(!$color) {
        [consolecolor]$default
    }
    elseif(($color -as [ConsoleColor]) -ne $null) {
        [consolecolor]$color
    }
    else {
        if("system.Windows.Media.Color" -as [type]) {
            #if its a transparent color, just use the background color of the host
            if($color -eq "#00FFFFFF") {$color = $host.PrivateData.ConsolePaneBackgroundColor}
            if($color -is [string]){ $color = [System.Windows.Media.Color]$color }
            [int]$bright = if($color.R -gt 128 -bor $color.G -gt 128 -bor $color.B -gt 128){8}else{0}
            [int]$r = if($color.R -gt 64){4}else{0}
            [int]$g = if($color.G -gt 64){2}else{0}
            [int]$b = if($color.B -gt 64){1}else{0}
            [consolecolor]($bright -bor $r -bor $g -bor $b)
        }
        else {
            throw "Unable to process hosts default colors $color"
        }
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
    @{ Name="Branch"; Expr={$_.Name}},
    @{ Name="IsHead"; Expr={ $_.IsCurrentRepositoryHead}}, "IsRemote", "IsTracking",
    @{ Name="Tip"; Expr={$_.Tip.Sha}},
    @{ Name="Remote"; expr = { $_.Remote.Url } },
    @{ Name="Ahead"; Expr= { $_.TrackingDetails.AheadBy }},
    @{ Name="Behind"; Expr = { $_.TrackingDetails.BehindBy }},
    @{ Name="CommonAncestor"; Expr={ $_.TrackingDetails.CommonAncestor.Sha }},
    @{ Name="GitDir"; Expr= {$_.Repository.Info.WorkingDirectory}}

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

        } finally {
            if($null -ne $repo) {
                $repo.Dispose()
            }
        }
    }
}
Set-Alias "Branch" "Get-Branch"

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
Set-Alias "Status" "Show-Status"

# Export-ModuleMember -Function *-* -Alias *

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
