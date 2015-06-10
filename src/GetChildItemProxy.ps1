Function Get-Childitem
{
    [CmdletBinding(DefaultParameterSetName='Items', SupportsTransactions=$true, HelpUri='http://go.microsoft.com/fwlink/?LinkID=113308')]
    param(
        [Parameter(ParameterSetName='Items', Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string[]]
        ${Path}=$pwd.Path,

        [Parameter(ParameterSetName='LiteralItems', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('PSPath')]
        [string[]]
        ${LiteralPath},

        [Parameter(Position=1)]
        [string]
        ${Filter},

        [string[]]
        ${Include},

        [string[]]
        ${Exclude},

        [Alias('s')]
        [switch]
        ${Recurse},

        [uint32]
        ${Depth},

        [switch]
        ${Force},

        [switch]
        ${Name})

    begin
    {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Management\Get-ChildItem', [System.Management.Automation.CommandTypes]::Cmdlet)
            write-debug "Path is: $path"
            if(![string]::IsNullOrEmpty($path) -and (Get-Command Get-GitRootFolder -ErrorAction SilentlyContinue) -and ($path | %{Get-GitRootFolder $_}))
            {
                $scriptCmd = {
                    & $wrappedCmd @PSBoundParameters | % -Begin {
                        $roots = $path | %{Get-GitRootFolder $_} | get-unique
                        $changes = foreach($root in $roots){Get-GitChange -root $root -ShowIgnored | select @{n='Path';e={join-path $root ($_.path -replace '\\\\$','\*')}},staged,change } 
                    } -Process {
                        
                        $fsItem = $_
                        $info = if($fsItem.PSIsContainer)
                        {
                            $changes|? {$fsItem.fullname -eq $_.path.TrimEnd('\','*') -or $fsItem.fullname -like $_.path }|select change, staged
                        }
                        else
                        {
                            $changes|? {$fsItem.fullname -like $_.path}|select change, staged
                        }
                        
                        

                        $fsItem | Add-Member -Name Change -value $info.change -MemberType NoteProperty
                        $fsItem | Add-Member -name Staged -Value $info.staged -MemberType NoteProperty
                        $null=$fsItem.pstypenames.insert(0,"$($fsItem.gettype().fullname)#git")
                        $fsItem
                    }
                }
            }
            else
            {
                $scriptCmd = {& $wrappedCmd @PSBoundParameters }
            }
            
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process
    {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end
    {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
}

Update-FormatData $PSScriptRoot\filesystem.format.ps1xml

