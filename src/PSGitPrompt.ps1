function Set-PromptSettings {
    [CmdletBinding()]
    param(
        [string]$BeforeText = "[",
        [ConsoleColor]$BeforeForeground,
        [ConsoleColor]$BeforeBackground,
        [string]$BranchText = $([char]0x03BB),
        [ConsoleColor]$BranchForeground,
        [ConsoleColor]$BranchBackground,
        [ConsoleColor]$AheadByForeground,
        [ConsoleColor]$AheadByBackground,
        [ConsoleColor]$BehindByForeground,
        [ConsoleColor]$BehindByBackground,
        [ConsoleColor]$IndexForeground,
        [ConsoleColor]$IndexBackground,
        [ConsoleColor]$WorkingForeground,
        [ConsoleColor]$WorkingBackground,
        [string]$AfterText = "]",
        [ConsoleColor]$AfterForeground,
        [ConsoleColor]$AfterBackground,
        [Switch]$HideZero
    )

    $config = Import-Configuration

    switch($PSBoundParameters.Keys) {
        "BeforeText" {
            $config.Before.Object = $PSBoundParameters[$_]
        }
        "BeforeForeground" {
            $config.Before.Foreground = $PSBoundParameters[$_]
        }
        "BeforeBackground" {
            $config.Before.Background = $PSBoundParameters[$_]
        }
        "BranchText" {
            $config.Branch.Object = $PSBoundParameters[$_]
        }
        "BranchForeground" {
            $config.Branch.Foreground = $PSBoundParameters[$_]
        }
        "BranchBackground" {
            $config.Branch.Background = $PSBoundParameters[$_]
        }
        "AheadByForeground" {
            $config.AheadBy.Foreground = $PSBoundParameters[$_]
        }
        "AheadByBackground" {
            $config.AheadBy.Background = $PSBoundParameters[$_]
        }
        "BehindByForeground" {
            $config.BehindBy.Foreground = $PSBoundParameters[$_]
        }
        "BehindByBackground" {
            $config.BehindBy.Background = $PSBoundParameters[$_]
        }
        "IndexForeground" {
            $config.Index.Foreground = $PSBoundParameters[$_]
        }
        "IndexBackground" {
            $config.Index.Background = $PSBoundParameters[$_]
        }
        "WorkingForeground" {
            $config.Working.Foreground = $PSBoundParameters[$_]
        }
        "WorkingBackground" {
            $config.Working.Background = $PSBoundParameters[$_]
        }
        "AfterText" {
            $config.After.Object = $PSBoundParameters[$_]
        }
        "AfterForeground" {
            $config.After.Foreground = $PSBoundParameters[$_]
        }
        "AfterBackground" {
            $config.After.Background = $PSBoundParameters[$_]
        }
        "HideZero" {
            $Config.HideZero =  $PSBoundParameters[$_]
        }
    }

    Export-Configuration $config
}

function Write-Text {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName=$true, Position=0)]
        $Object, 

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Alias("Foreground")]
        [ConsoleColor]$ForegroundColor, 

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Alias("Background")]
        [ConsoleColor]$BackgroundColor
    )
    process {
        Write-Verbose ($PSBoundParameters | Out-String)
        Write-Host -NoNewLine @PSBoundParameters
    }
}

function Write-Status {
    [CmdletBinding()]
    param (
        $Status,
        $Config
    )
    end {
        if(!$Status) { $Status = Get-Status }
        if(!$Config) { $Config = Import-Configuration }

        if($Status -and $Config) {
            $config.Before | Write-Text
            $config.Branch | Write-Text
            $config.Branch | Write-Text ($Status.Branch + " ")
            if($Status.AheadBy -gt 0) {
                $config.AheadBy | Write-Text
                $config.AheadBy | Write-Text ($Status.AheadBy + " ")
            }
            if($Status.BehindBy -gt 0) {
                $config.BehindBy | Write-Text
                $config.BehindBy | Write-Text ($Status.BehindBy + " ")
            }

            if(0 -ne ($Status.Changes | Where { $_.Staged }).Length) {
                $count = @($Status.Changes | Where { $_.Staged -and ($_.Change -eq "Added") }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.Index | Write-Text "+$count "
                }
                $count = @($Status.Changes | Where { $_.Staged -and ($_.Change -eq "Modified") }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.Index | Write-Text "~$count "
                }
                $count = @($Status.Changes | Where { $_.Staged -and ($_.Change -eq "Removed") }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.Index | Write-Text "-$count "
                }
                $count = @($Status.Changes | Where { $_.Staged -and ($_.Change -eq "Renamed") }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.Index | Write-Text "%$count "
                }
                # We might need some sort of separator if there's both types of data
                if(0 -ne @($Status.Changes | Where { !$_.Staged }).Length) {
                    $config.Separator | Write-Text
                }
            }
            if(0 -ne ($Status.Changes | Where { !$_.Staged }).Length) {
                # We might need some sort of separator if there's both types of data
                if(0 -eq @($Status.Changes | Where { $_.Staged }).Length) {
                    $config.Separator | Write-Text
                }                
                if(0 -lt ($count = @($Status.Changes | Where { !$_.Staged -and ($_.Change -eq "Added") }).Length) -or !$config.HideZero) {
                    $config.Working | Write-Text "+$count "
                }
                if(0 -lt ($count = @($Status.Changes | Where { !$_.Staged -and ($_.Change -eq "Modified") }).Length) -or !$config.HideZero) {
                    $config.Working | Write-Text "~$count "
                }
                if(0 -lt ($count = @($Status.Changes | Where { !$_.Staged -and ($_.Change -eq "Removed") }).Length) -or !$config.HideZero) {
                    $config.Working | Write-Text "-$count "
                }
                if(0 -lt ($count = @($Status.Changes | Where { !$_.Staged -and ($_.Change -eq "Renamed") }).Length) -or !$config.HideZero) {
                    $config.Working | Write-Text "%$count "
                }
            }
            $config.After | Write-Text 
        } else {
            $config.NoStatus | Write-Text 
        }
    }
}

# This stuff leaks out on purpose
if(!(Test-Path Variable:Global:VcsPromptStatuses)) {
    $Global:VcsPromptStatuses = @()
}

function Global:Write-VcsStatus { $Global:VcsPromptStatuses | foreach { & $_ } }

# Add scriptblock that will execute for Write-VcsStatus
$Global:VcsPromptStatuses = @($Global:VcsPromptStatuses) + @({
    $WarningPreference, $WP = "SilentlyContinue", $WarningPreference
    Write-Status
    $WarningPreference = $WP
})

# but we don't want any duplicate hooks (if people import the module twice)
$Global:VcsPromptStatuses = @( $Global:VcsPromptStatuses | Select -Unique )
