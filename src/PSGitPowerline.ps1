function New-PowerLineBlock {
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
        $Parameters
    }
}

function Get-StatusPowerLine {
    [CmdletBinding()]
    param (
        $Status,
        $Config
    )
    end {
        if(!$Status) { $Status = Get-Status }
        if(!$Config) { $Config = Import-Configuration }

        if($Status -and $Config) {
            $config.Before | New-PowerLineBlock
            $config.Branch | New-PowerLineBlock
            $config.Branch | New-PowerLineBlock ($Status.Branch + " ")
            if($Status.AheadBy -gt 0) {
                $config.AheadBy | New-PowerLineBlock
                $config.AheadBy | New-PowerLineBlock ($Status.AheadBy + " ")
            }
            if($Status.BehindBy -gt 0) {
                $config.BehindBy | New-PowerLineBlock
                $config.BehindBy | New-PowerLineBlock ($Status.BehindBy + " ")
            }

            $StagedChanges = @($Status.Changes | Where { $_.Staged })
            $UnStagedChanges = @($Status.Changes | Where { !$_.Staged })

            if(($StagedChanges.Length -gt 0 -or $UnStagedChanges.Length -gt 0) -and $config.BeforeChanges.Object) {
                $config.BeforeChanges | New-PowerLineBlock
            }

            if(0 -ne $StagedChanges.Length) {
                $count = @($StagedChanges | Where { $_.Change -eq "Added" }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.StagedChanges | New-PowerLineBlock "+$count "
                }
                $count = @($StagedChanges | Where { $_.Change -eq "Modified" }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.StagedChanges | New-PowerLineBlock "~$count "
                }
                $count = @($StagedChanges | Where { $_.Change -eq "Removed" }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.StagedChanges | New-PowerLineBlock "-$count "
                }
                $count = @($StagedChanges | Where { $_.Change -eq "Renamed" }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.StagedChanges | New-PowerLineBlock "%$count "
                }
            }

            if(($StagedChanges.Length -gt 0 -and $UnStagedChanges.Length -gt 0) -and $config.Separator.Object) {
                $config.Separator | New-PowerLineBlock
            }

            if(0 -ne $UnStagedChanges.Length) {
                $count = @($UnStagedChanges | Where { $_.Change -eq "Added" }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.UnStagedChanges | New-PowerLineBlock "+$count "
                }
                $count = @($UnStagedChanges | Where { $_.Change -eq "Modified" }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.UnStagedChanges | New-PowerLineBlock "~$count "
                }
                $count = @($UnStagedChanges | Where { $_.Change -eq "Removed" }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.UnStagedChanges | New-PowerLineBlock "-$count "
                }
                $count = @($UnStagedChanges | Where { $_.Change -eq "Renamed" }).Length
                if(0 -lt $count -or !$config.HideZero) {
                    $config.UnStagedChanges | New-PowerLineBlock "%$count "
                }
            }

            if(($StagedChanges.Length -gt 0 -or $UnStagedChanges.Length -gt 0) -and $config.AfterChanges.Object) {
                $config.AfterChanges | New-PowerLineBlock
            }
            if(($StagedChanges.Length -eq 0 -and $UnStagedChanges.Length -eq 0) -and $config.AfterNoChanges.Object) {
                $config.AfterNoChanges | New-PowerLineBlock
            }

        } else {
            $config.NoStatus | New-PowerLineBlock
        }
    }
}
