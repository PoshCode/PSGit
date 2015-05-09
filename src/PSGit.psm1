# TODO: This is just a stub to make the first test pass
function Get-Status {
    [CmdletBinding()]
    param(
        [Parameter()]
        [String]$Path
    )
    end {
        Write-Warning "The path is not in a git repository!"
    }
}

function Get-Info {
    [CmdletBinding()]
    param(
        [Parameter()]
        [String]$Path
    )
    process {
        Write-Warning "The path is not in a git repository!"
    }
}
