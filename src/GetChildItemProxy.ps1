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
            
            Write-Verbose "path: $path" -Verbose
            Write-Verbose "path type: $($path.gettype())" -Verbose
            Write-Verbose "path count: $($path.Count)" -Verbose
            
            if(![string]::IsNullOrEmpty($path) -and (Get-GitRootFolder $Path))
            {
                $scriptCmd = {
                    & $wrappedCmd @PSBoundParameters | % -Begin {
                        $root = Get-GitRootFolder "$Path"
                        $changes = Get-GitChange -Root $root  | select @{n='Path';e={join-path $root $_.path}},staged,change 
                    } -Process {
                        $file = $_
                        $change = $changes|? path -eq $file.fullname|select -ExpandProperty change
                        $staged = $changes|? path -eq $file.fullname|select -ExpandProperty staged

                        $file | Add-Member -Name Change -value $change -MemberType NoteProperty
                        $file | Add-Member -name Staged -Value $staged -MemberType NoteProperty
                        $null=$file.pstypenames.insert(0,"$($file.gettype().fullname)#git")
                        $file
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