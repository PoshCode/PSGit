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

        [string]$BeforeChanges = '',
        [ConsoleColor]$BeforeChangesForeground,
        [ConsoleColor]$BeforeChangesBackground,

        [ConsoleColor]$StagedChangesForeground,
        [ConsoleColor]$StagedChangesBackground,

        [string]$Separator = '|',
        [ConsoleColor]$SeparatorForeground,
        [ConsoleColor]$SeparatorBackground,

        [ConsoleColor]$UnStagedChangesForeground,
        [ConsoleColor]$UnStagedChangesBackground,

        [string]$AfterChanges = "]:",
        [ConsoleColor]$AfterChangesForeground,
        [ConsoleColor]$AfterChangesBackground,

        [string]$AfterNoChanges = "]:",
        [ConsoleColor]$AfterNoChangesForeground,
        [ConsoleColor]$AfterNoChangesBackground,
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
        "BeforeChangesText" {
            $config.BeforeChanges.Object = $PSBoundParameters[$_]
        }
        "BeforeChangesForeground" {
            $config.BeforeChanges.Foreground = $PSBoundParameters[$_]
        }
        "BeforeChangesBackground" {
            $config.BeforeChanges.Background = $PSBoundParameters[$_]
        }
        "StagedChangesForeground" {
            $config.StagedChanges.Foreground = $PSBoundParameters[$_]
        }
        "StagedChangesBackground" {
            $config.StagedChanges.Background = $PSBoundParameters[$_]
        }
        "UnStagedChangesForeground" {
            $config.UnStagedChanges.Foreground = $PSBoundParameters[$_]
        }
        "UnStagedChangesBackground" {
            $config.UnStagedChanges.Background = $PSBoundParameters[$_]
        }
        "AfterChangesText" {
            $config.AfterChanges.Object = $PSBoundParameters[$_]
        }
        "AfterChangesForeground" {
            $config.AfterChanges.Foreground = $PSBoundParameters[$_]
        }
        "AfterChangesBackground" {
            $config.AfterChanges.Background = $PSBoundParameters[$_]
        }
        "AfterNoChangesText" {
            $config.AfterNoChanges.Object = $PSBoundParameters[$_]
        }
        "AfterNoChangesForeground" {
            $config.AfterNoChanges.Foreground = $PSBoundParameters[$_]
        }
        "AfterNoChangesBackground" {
            $config.AfterNoChanges.Background = $PSBoundParameters[$_]
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
        [Alias("Content","text")]
        $Object,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Alias("fg","Foreground")]
        $ForegroundColor,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Alias("bg","Background")]
        $BackgroundColor
    )
    process {
        $Parameters = @{} + $PSBoundParameters
        $Null = $PSBoundParameters.GetEnumerator() | Where Value -eq $null | % { $Parameters.Remove($_.Key) }
        Write-Debug ($Parameters | Out-String)
        Write-Host -NoNewLine @Parameters
    }
}

function Write-Status {
    [CmdletBinding()]
    param (
        $Status,
        $Config
    )
    end {
        if(!$Status) { $Status = Get-Status -WarningAction SilentlyContinue}
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

            $StagedChanges = @($Status.Changes | Where { $_.Staged })
            $UnStagedChanges = @($Status.Changes | Where { !$_.Staged })

            if(($StagedChanges.Length -gt 0 -or $UnStagedChanges.Length -gt 0) -and $config.BeforeChanges.Object) {
                $config.BeforeChanges | Write-Text
            }

            if(0 -ne $StagedChanges.Length) {
                $count = @($StagedChanges | Where { $_.Change -eq "Added" }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.StagedChanges | Write-Text "+$count "
                }
                $count = @($StagedChanges | Where { $_.Change -eq "Modified" }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.StagedChanges | Write-Text "~$count "
                }
                $count = @($StagedChanges | Where { $_.Change -eq "Removed" }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.StagedChanges | Write-Text "-$count "
                }
                $count = @($StagedChanges | Where { $_.Change -eq "Renamed" }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.StagedChanges | Write-Text "%$count "
                }
            }

            if(($StagedChanges.Length -gt 0 -and $UnStagedChanges.Length -gt 0) -and $config.Separator.Object) {
                $config.Separator | Write-Text
            }

            if(0 -ne $UnStagedChanges.Length) {
                $count = @($UnStagedChanges | Where { $_.Change -eq "Added" }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.UnStagedChanges | Write-Text "+$count "
                }
                $count = @($UnStagedChanges | Where { $_.Change -eq "Modified" }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.UnStagedChanges | Write-Text "~$count "
                }
                $count = @($UnStagedChanges | Where { $_.Change -eq "Removed" }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.UnStagedChanges | Write-Text "-$count "
                }
                $count = @($UnStagedChanges | Where { $_.Change -eq "Renamed" }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.UnStagedChanges | Write-Text "%$count "
                }
            }

            if(($StagedChanges.Length -gt 0 -or $UnStagedChanges.Length -gt 0) -and $config.AfterChanges.Object) {
                $config.AfterChanges | Write-Text
            }
            if(($StagedChanges.Length -eq 0 -and $UnStagedChanges.Length -eq 0) -and $config.AfterNoChanges.Object) {
                $config.AfterNoChanges | Write-Text
            }

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
