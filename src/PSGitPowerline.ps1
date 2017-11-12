Set-Alias Get-StatusPowerLine Write-StatusPowerLine
function Write-StatusPowerLine {
    [CmdletBinding()]
    param (
        $Status,
        $Config
    )
    end {
        if(!$Status) { $Status = Get-Status -WarningAction SilentlyContinue }
        if(!$Config) { $Config = Import-Configuration }

        if($Status -and $Config) {
            $config.Branch | New-PowerLineBlock ("$($config.Branch.Object)" + $Status.Branch)
            if($Status.AheadBy -gt 0) {
                $config.AheadBy | New-PowerLineBlock ("$($config.AheadBy.Object)" + $Status.AheadBy)
            }
            if($Status.BehindBy -gt 0) {
                $config.BehindBy | New-PowerLineBlock ("$($config.BehindBy.Object)" + $Status.BehindBy)
            }

            $StagedChanges = @($Status.Changes | Where { $_.Staged })
            $UnStagedChanges = @($Status.Changes | Where { !$_.Staged })

            if(0 -ne $StagedChanges.Length) {
                $config.StagedChanges | New-PowerLineBlock $($(
                    $count = @($StagedChanges | Where { $_.Change -eq "Added" }).Length
                    if(0 -lt $count -or !$config.HideZero) { "+$count" }

                    $count = @($StagedChanges | Where { $_.Change -eq "Modified" }).Length
                    if(0 -lt $count -or !$config.HideZero) { "~$count" }

                    $count = @($StagedChanges | Where { $_.Change -eq "Removed" }).Length
                    if(0 -lt $count -or !$config.HideZero) { "-$count" }

                    $count = @($StagedChanges | Where { $_.Change -eq "Renamed" }).Length
                    if(0 -lt $count -or !$config.HideZero) { "%$count" }
                ) -join " ")
            }

            if(0 -ne $UnStagedChanges.Length) {
                $config.UnStagedChanges | New-PowerLineBlock $($(
                    $count = @($UnStagedChanges | Where { $_.Change -eq "Added" }).Length
                    if(0 -lt $count -or !$config.HideZero) { "+$count" }

                    $count = @($UnStagedChanges | Where { $_.Change -eq "Modified" }).Length
                    if(0 -lt $count -or !$config.HideZero) { "~$count" }

                    $count = @($UnStagedChanges | Where { $_.Change -eq "Removed" }).Length
                    if(0 -lt $count -or !$config.HideZero) { "-$count" }

                    $count = @($UnStagedChanges | Where { $_.Change -eq "Renamed" }).Length
                    if(0 -lt $count -or !$config.HideZero) { "%$count" }
                ) -join " ")
            }
        }
    }
}

function SetPSGit {
    [CmdletBinding()]
    param()

    if(Get-Command Add-PowerLineBloc[k]) {
        Add-PowerLineBlock { Write-GitStatusPowerLine } -AutoRemove
    } else {
        Write-Warning "Modifying `$Prompt list. Ensure you have a prompt function that invokes it's ScriptBlocks."
        if ($Global:Prompt -is [System.Collections.IList]) {
            $Index = [Math]::Max(0, ($Global:Prompt.Count - 2));
            $Global:Prompt.Insert($Index, { Write-GitStatusPowerLine })
        } else {
            [System.Collections.Generic.List[ScriptBlock]]$Global:Prompt = [ScriptBlock[]]@({ Write-GitStatusPowerLine })
        }

        $MyInvocation.MyCommand.Module.OnRemove = {
            $Prompt.RemoveAt( @($Prompt).ForEach{$_.ToString().Trim()}.IndexOf("Write-GitStatusPowerLine") )
        }
    }
}

SetPSGit