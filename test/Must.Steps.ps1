# These are not really steps!
# This is the deffinition of the Must assertion for Pester tests.

function Must {
    [CmdletBinding(DefaultParameterSetName='equal', HelpUri='http://go.microsoft.com/fwlink/?LinkID=113423', RemotingCapability='None')]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [psobject]
        ${InputObject},

        [Switch]
        $Not,

        [Switch]
        $All,

        [Switch]
        $Any,

        # [Parameter(ParameterSetName='ScriptBlockSet', Mandatory=$true, Position=0)]
        # [scriptblock]
        # ${FilterScript},

        [Parameter(Position=0)]
        [AllowEmptyString()][AllowNull()]
        [System.Object]
        ${Property},

        [Parameter(Position=1)]
        [AllowEmptyString()][AllowNull()]
        [System.Object]
        ${Value},

        [Parameter(ParameterSetName='equal', Mandatory=$true)]
        [Alias('IEQ')]
        [Alias('BeEqualTo')]
        [Alias('Equal')]
        [switch]
        ${EQ},

        [Parameter(ParameterSetName='equal (case-sensitive)', Mandatory=$true)]
        [Alias('BeExactlyEqualTo')]
        [Alias('EqualExactly')]
        [switch]
        ${CEQ},

        [Parameter(ParameterSetName='not equal', Mandatory=$true)]
        [Alias('INE')]
        [Alias('NotBeEqualTo')]
        [Alias('NotEqual')]
        [switch]
        ${NE},

        [Parameter(ParameterSetName='not equal (case-sensitive)', Mandatory=$true)]
        [Alias('NotBeExactlyEqualTo')]
        [Alias('NotExactlyEqual')]
        [switch]
        ${CNE},

        [Parameter(ParameterSetName='be greater than', Mandatory=$true)]
        [Alias('IGT')]
        [Alias('BeGreaterThan')]
        [switch]
        ${GT},

        [Parameter(ParameterSetName='be greater than (case-sensitive)', Mandatory=$true)]
        [switch]
        [Alias('BeExactlyGreaterThan')]
        ${CGT},

        [Parameter(ParameterSetName='be less than', Mandatory=$true)]
        [Alias('ILT')]
        [Alias('BeLessThan')]
        [switch]
        ${LT},

        [Parameter(ParameterSetName='be less than (case-sensitive)', Mandatory=$true)]
        [Alias('BeExactlyLessThan')]
        [switch]
        ${CLT},

        [Parameter(ParameterSetName='not be less than', Mandatory=$true)]
        [Alias('NotBeLessThan')]
        [Alias('IGE')]
        [switch]
        ${GE},

        [Parameter(ParameterSetName='not be less than (case-sensitive)', Mandatory=$true)]
        [Alias('NotBeExactlyLessThan')]
        [switch]
        ${CGE},

        [Parameter(ParameterSetName='not be greater than', Mandatory=$true)]
        [Alias('ILE')]
        [Alias('NotBeGreaterThan')]
        [switch]
        ${LE},

        [Parameter(ParameterSetName='not be greater than (case-sensitive)', Mandatory=$true)]
        [Alias('NotBeExactlyGreaterThan')]
        [switch]
        ${CLE},

        [Parameter(ParameterSetName='be like', Mandatory=$true)]
        [Alias('ILike')]
        [Alias('BeLike')]
        [switch]
        ${Like},

        [Parameter(ParameterSetName='be like (case-sensitive)', Mandatory=$true)]
        [Alias('BeExactlyLike')]
        [switch]
        ${CLike},

        [Parameter(ParameterSetName='not be like', Mandatory=$true)]
        [Alias('NotBeLike')]
        [Alias('INotLike')]
        [switch]
        ${NotLike},

        [Parameter(ParameterSetName='not be like (case-sensitive)', Mandatory=$true)]
        [Alias('NotBeExactlyLike')]
        [switch]
        ${CNotLike},

        [Parameter(ParameterSetName='match', Mandatory=$true)]
        [Alias('IMatch')]
        [switch]
        ${Match},

        [Parameter(ParameterSetName='match (case-sensitive)', Mandatory=$true)]
        [Alias('MatchExactly')]
        [switch]
        ${CMatch},

        [Parameter(ParameterSetName='not match', Mandatory=$true)]
        [Alias('INotMatch')]
        [switch]
        ${NotMatch},

        [Parameter(ParameterSetName='not match (case-sensitive)', Mandatory=$true)]
        [Alias('NotMatchExactly')]
        [switch]
        ${CNotMatch},

        [Parameter(ParameterSetName='contain', Mandatory=$true)]
        [Alias('IContains')]
        [switch]
        ${Contains},

        [Parameter(ParameterSetName='contain (case-sensitive)', Mandatory=$true)]
        [Alias('ContainsExactly')]
        [Alias('ContainExactly')]
        [switch]
        ${CContains},

        [Parameter(ParameterSetName='not contain', Mandatory=$true)]
        [Alias('INotContains')]
        [switch]
        ${NotContains},

        [Parameter(ParameterSetName='not contain (case-sensitive)', Mandatory=$true)]
        [Alias('NotContainsExactly')]
        [Alias('NotContainExactly')]
        [switch]
        ${CNotContains},

        [Parameter(ParameterSetName='be in', Mandatory=$true)]
        [Alias('IIn')]
        [Alias('BeIn')]
        [switch]
        ${In},

        [Parameter(ParameterSetName='be in (case-sensitive)', Mandatory=$true)]
        [Alias('BeInExactly')]
        [switch]
        ${CIn},

        [Parameter(ParameterSetName='not be in', Mandatory=$true)]
        [Alias('INotIn')]
        [Alias('NotBeIn')]
        [switch]
        ${NotIn},

        [Parameter(ParameterSetName='not be in (case-sensitive)', Mandatory=$true)]
        [Alias('NotBeInExactly')]
        [switch]
        ${CNotIn},

        [Parameter(ParameterSetName='be of type', Mandatory=$true)]
        [Alias('BeOfType')]
        [switch]
        ${Is},

        [Parameter(ParameterSetName='not be of type', Mandatory=$true)]
        [Alias('NotBeOfType')]
        [switch]
        ${IsNot},

        [Parameter(ParameterSetName='be null or empty', Mandatory=$true)]
        [switch]
        ${BeNullOrEmpty}
    )
begin
{
    $NoProperty = $False

    try {

        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

        $null = $PSBoundParameters.Remove("Not")
        $null = $PSBoundParameters.Remove("All")
        $null = $PSBoundParameters.Remove("Any")

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('ForEach-Object', [System.Management.Automation.CommandTypes]::Cmdlet)
        $NullOrEmptyFilter = { if($_ -is [System.Collections.IList]) { $_.Count -eq 0 } elseif( $_ -is [string] ) { [string]::IsNullOrEmpty($_) } else { $_ -eq $null } }


        if (!$PSBoundParameters.ContainsKey('Value'))
        {
            $NoProperty = $True
            if($PSBoundParameters.ContainsKey('BeNullOrEmpty')) {
                $NullOrEmptyFilter = { if($_.Value -is [System.Collections.IList]) { $_.Value.Count -eq 0 } elseif( $_.Value -is [string] ) { [string]::IsNullOrEmpty($_.Value) } else { $_.Value -eq $null } }
            } else {
                $Value = $PSBoundParameters['Value'] = $PSBoundParameters['Property']
                $Property = $PSBoundParameters['Property'] = "Value"
            }

            if($PSBoundParameters.ContainsKey('InputObject'))
            {
                $InputObject = $PSBoundParameters['InputObject'] = New-Object PSObject -Property @{ "Value" = $InputObject }
            }
        }
        <#
        if(!($Cmdlet = (Get-Variable PSCmdlet -Scope 1 -EA 0).Value)) {
            if(!($Cmdlet = (Get-Variable PSCmdlet -Scope 2 -EA 0).Value)) {
                if(!($Cmdlet = (Get-Variable PSCmdlet -Scope 3 -EA 0).Value)) {
                    if(!($Cmdlet = (Get-Variable PSCmdlet -Scope 4 -EA 0).Value)) {
                        $Cmdlet = $PSCmdlet
                    }
                }
            }
        }
        #>
        $Cmdlet = $PSCmdlet
        $ThrowMessage = {
            if(!$_) {
                $message = @("TestObject", $Property, "must")
                $message += if($Not) { "not" }
                $message += if($All) { "all" }
                $message += if($Any) { "any" }
                $message += $PSCmdlet.ParameterSetName
                $message += "'$($Value -join "','")'"
                $message += if($NoProperty) { 
                        if($InputObject -eq $null) {
                            '-- Actual: $null'
                        } else {
                            "-- Actual: '" + $InputObject + "'" 
                        }
                    } else {
                        if($InputObject.$Property -eq $null) {
                            '-- Actual: $null'
                        } else {
                            "-- Actual: '" + $InputObject.$Property + "'"
                        }
                    }

                $exception = New-Object AggregateException ($message -join " ")
                $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, "FailedMust", "LimitsExceeded", $message
                $Cmdlet.ThrowTerminatingError($errorRecord)
            }
        }


        $Parameters = @{} + $PSBoundParameters
        if($Parameters.ContainsKey('BeNullOrEmpty')) {
            $null = $Parameters.Remove("BeNullOrEmpty")
            $Parameters.FilterScript = $NullOrEmptyFilter

            if($All) {
                if($Not) {
                    $scriptCmd = {& $wrappedCmd { if($_ -eq $null){ $False } else { ($_ | Where-Object @Parameters) -eq $null } } | ForEach-Object {[Array]$Collected=@()} {$Collected += $_} {$Collected -NotContains $False} | ForEach-Object $ThrowMessage }
                } else {
                    $scriptCmd = {& $wrappedCmd { if($_ -eq $null){ $True } else { ($_ | Where-Object @Parameters) -ne $null } } | ForEach-Object {[Array]$Collected=@()} {$Collected += $_} {$Collected -NotContains $False} | ForEach-Object $ThrowMessage }
                }
            } elseif($Any) {
                if($Not) {
                    $scriptCmd = {& $wrappedCmd { if($_ -eq $null){ $False } else { ($_ | Where-Object @Parameters) -eq $null } } | ForEach-Object {[Array]$Collected=@()} {$Collected += $_} {$Collected -Contains $True} | ForEach-Object $ThrowMessage }
                } else {
                    $scriptCmd = {& $wrappedCmd { if($_ -eq $null){ $True } else { ($_ | Where-Object @Parameters) -ne $null } } | ForEach-Object {[Array]$Collected=@()} {$Collected += $_} {$Collected -Contains $True} | ForEach-Object $ThrowMessage }
                }
            } else {
                if($Not) {
                    $scriptCmd = {& $wrappedCmd { if($_ -eq $null){ $False } else { ($_ | Where-Object @Parameters) -eq $null } } | ForEach-Object $ThrowMessage }
                } else {
                    $scriptCmd = {& $wrappedCmd { if($_ -eq $null){ $True } else { ($_ | Where-Object @Parameters) -ne $null } } | ForEach-Object $ThrowMessage }
                }
            }
        } else {

            if($All) {
                if($Not) {
                    $scriptCmd = {& $wrappedCmd { ($_ | Where-Object @Parameters) -eq $null } | ForEach-Object {[Array]$Collected=@()} {$Collected += $_} {$Collected -NotContains $False} | ForEach-Object $ThrowMessage }
                } else {
                    $scriptCmd = {& $wrappedCmd { ($_ | Where-Object @Parameters) -ne $null } | ForEach-Object {[Array]$Collected=@()} {$Collected += $_} {$Collected -NotContains $False} | ForEach-Object $ThrowMessage }
                }
            } elseif($Any) {
                if($Not) {
                    $scriptCmd = {& $wrappedCmd { ($_ | Where-Object @Parameters) -eq $null } | ForEach-Object {[Array]$Collected=@()} {$Collected += $_} {$Collected -Contains $True} | ForEach-Object $ThrowMessage }
                } else {
                    $scriptCmd = {& $wrappedCmd { ($_ | Where-Object @Parameters) -ne $null } | ForEach-Object {[Array]$Collected=@()} {$Collected += $_} {$Collected -Contains $True} | ForEach-Object $ThrowMessage }
                }
            } else {
                if($Not) {
                    $scriptCmd = {& $wrappedCmd { ($_ | Where-Object @Parameters) -eq $null } | ForEach-Object $ThrowMessage }
                } else {
                    $scriptCmd = {& $wrappedCmd { ($_ | Where-Object @Parameters) -ne $null } | ForEach-Object $ThrowMessage }
                }
            }
        }

        $NeedPipelineInput = $PSCmdlet.MyInvocation.ExpectingInput
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $NeedPipelineInput = $False
        if($NoProperty) {
            $_ = @{ "Value" = $_ }
        }
        $steppablePipeline.Process($_)

    } catch {
        throw
    }
}

end
{
    try {
        if($NeedPipelineInput -and !${BeNullOrEmpty} -and !$Not) {
            ForEach-Object $ThrowMessage -Input $Null
        }
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Where-Object
.ForwardHelpCategory Cmdlet

#>
}


# function Must {
#    [CmdletBinding(DefaultParameterSetName = 'Be')]
#    param(


#       $lt,
#       $le,
#       $gt,
#       $ge,
#       $eq,
#       $ne
#    )

#    $all = @(
#       if($lt) { $Version -lt $lt }
#       if($gt) { $Version -gt $gt }
#       if($le) { $Version -le $le }
#       if($ge) { $Version -ge $ge }
#       if($eq) { $Version -eq $eq }
#       if($ne) { $Version -ne $ne }
#    )

#    $all -notcontains $false
# }
