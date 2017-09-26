function Set-PromptSettings {
    [CmdletBinding()]
    param(
        [string]$AfterChangesText = "]:",
        [PoshCode.Pansies.RgbColor]$AfterChangesForeground,
        [PoshCode.Pansies.RgbColor]$AfterChangesBackground,

        [string]$AfterNoChangesText = "]:",
        [PoshCode.Pansies.RgbColor]$AfterNoChangesForeground,
        [PoshCode.Pansies.RgbColor]$AfterNoChangesBackground,

        [string]$AheadByText = '▲',
        [PoshCode.Pansies.RgbColor]$AheadByForeground,
        [PoshCode.Pansies.RgbColor]$AheadByBackground,

        [string]$BehindByText = '▼',
        [PoshCode.Pansies.RgbColor]$BehindByForeground,
        [PoshCode.Pansies.RgbColor]$BehindByBackground,

        [string]$BeforeText = "[",
        [PoshCode.Pansies.RgbColor]$BeforeForeground,
        [PoshCode.Pansies.RgbColor]$BeforeBackground,

        [string]$BranchText = $([char]0x03BB),
        [PoshCode.Pansies.RgbColor]$BranchForeground,
        [PoshCode.Pansies.RgbColor]$BranchBackground,

        [string]$BeforeChangesText = '',
        [PoshCode.Pansies.RgbColor]$BeforeChangesForeground,
        [PoshCode.Pansies.RgbColor]$BeforeChangesBackground,

        [string]$SeparatorText = '|',
        [PoshCode.Pansies.RgbColor]$SeparatorForeground,
        [PoshCode.Pansies.RgbColor]$SeparatorBackground,

        [PoshCode.Pansies.RgbColor]$StagedChangesForeground,
        [PoshCode.Pansies.RgbColor]$StagedChangesBackground,

        [PoshCode.Pansies.RgbColor]$UnStagedChangesForeground,
        [PoshCode.Pansies.RgbColor]$UnStagedChangesBackground,

        [string]$NoStatusText = ':',
        [PoshCode.Pansies.RgbColor]$NoStatusForeground,
        [PoshCode.Pansies.RgbColor]$NoStatusBackground,

        [PoshCode.Pansies.RgbColor]$IndexForeground,
        [PoshCode.Pansies.RgbColor]$IndexBackground,

        [PoshCode.Pansies.RgbColor]$WorkingForeground,
        [PoshCode.Pansies.RgbColor]$WorkingBackground,

        [Switch]$HideZero
    )

    $config = Import-Configuration
    switch($PSBoundParameters.Keys) {
        "AfterChangesText" { $config.AfterChanges.Object = $PSBoundParameters[$_] }
        "AfterChangesBackground" { $config.AfterChanges.Background = $PSBoundParameters[$_] }
        "AfterChangesForeground" { $config.AfterChanges.Foreground = $PSBoundParameters[$_] }

        "AfterNoChangesText" { $config.AfterNoChanges.Object = $PSBoundParameters[$_] }
        "AfterNoChangesBackground" { $config.AfterNoChanges.Background = $PSBoundParameters[$_] }
        "AfterNoChangesForeground" { $config.AfterNoChanges.Foreground = $PSBoundParameters[$_] }

        "AheadByText" { $config.AheadBy.Object = $PSBoundParameters[$_] }
        "AheadByBackground" { $config.AheadBy.Background = $PSBoundParameters[$_] }
        "AheadByForeground" { $config.AheadBy.Foreground = $PSBoundParameters[$_] }

        "BeforeText" { $config.Before.Object = $PSBoundParameters[$_] }
        "BeforeBackground" { $config.Before.Background = $PSBoundParameters[$_] }
        "BeforeForeground" { $config.Before.Foreground = $PSBoundParameters[$_] }

        "BeforeChangesText" { $config.BeforeChanges.Object = $PSBoundParameters[$_] }
        "BeforeChangesBackground" { $config.BeforeChanges.Background = $PSBoundParameters[$_] }
        "BeforeChangesForeground" { $config.BeforeChanges.Foreground = $PSBoundParameters[$_] }

        "BehindByText" { $config.BehindBy.Object = $PSBoundParameters[$_] }
        "BehindByBackground" { $config.BehindBy.Background = $PSBoundParameters[$_] }
        "BehindByForeground" { $config.BehindBy.Foreground = $PSBoundParameters[$_] }

        "BranchText" { $config.Branch.Object = $PSBoundParameters[$_] }
        "BranchBackground" { $config.Branch.Background = $PSBoundParameters[$_] }
        "BranchForeground" { $config.Branch.Foreground = $PSBoundParameters[$_] }

        "SeparatorText" { $Config.Separator.Object = $PSBoundParameters[$_] }
        "SeparatorBackground" { $Config.Separator.Background = $PSBoundParameters[$_] }
        "SeparatorForeground" { $Config.Separator.Foreground = $PSBoundParameters[$_] }

        "StagedChangesBackground" { $config.StagedChanges.Background = $PSBoundParameters[$_] }
        "StagedChangesForeground" { $config.StagedChanges.Foreground = $PSBoundParameters[$_] }

        "UnStagedChangesBackground" { $config.UnStagedChanges.Background = $PSBoundParameters[$_] }
        "UnStagedChangesForeground" { $config.UnStagedChanges.Foreground = $PSBoundParameters[$_] }

        "NoStatusText" { $config.NoStatus.Text = $PSBoundParameters[$_] }
        "NoStatusForeground" { $config.NoStatus.Foreground = $PSBoundParameters[$_] }
        "NoStatusBackground" { $config.NoStatus.Background = $PSBoundParameters[$_] }

        "IndexForeground" { $config.Index.Foreground = $PSBoundParameters[$_] }
        "IndexBackground" { $config.Index.Background = $PSBoundParameters[$_] }

        "WorkingForeground" { $config.Working.Foreground = $PSBoundParameters[$_] }
        "WorkingBackground" { $config.Working.Background = $PSBoundParameters[$_] }

        "HideZero" { $Config.HideZero = [bool]$HideZero }
    }

    # function Clear-Config {
    #     [CmdletBinding()]
    #     param(
    #         [AllowNull()][AllowEmptyString()]
    #         [Parameter(ValueFromPipelineByPropertyName)]
    #         [String]$Text,

    #         [AllowNull()][AllowEmptyString()]
    #         [Parameter(ValueFromPipelineByPropertyName)]
    #         [PoshCode.Pansies.RgbColor]$Foreground,

    #         [AllowNull()][AllowEmptyString()]
    #         [Parameter(ValueFromPipelineByPropertyName)]
    #         [PoshCode.Pansies.RgbColor]$Background
    #     )
    #     $Properties = @{} + $PSBoundParameters
    #     foreach($key in @($Properties.Keys)) {
    #         if($Properties.$key -eq "" -or $Properties.$Key -eq $Null) {
    #             $null = $Properties.Remove($Key)
    #         }
    #     }
    #     [PSCustomObject]$Properties
    # }

    # foreach($section in "AfterChanges","AfterNoChanges","AheadBy","Before","BeforeChanges","BehindBy","Branch","Separator","StagedChanges","UnStagedChanges","NoStatus","Index","Working") {
    #     $config.$section = $config.$section | Clear-Config
    # }

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
        # Write-Debug ($Parameters | Out-String)
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
