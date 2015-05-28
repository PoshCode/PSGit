<#
When "WriteMessage ((?<type>\S+)\s+(?<message>\S+))? ?is called" {
    param($type,$message)
    Mock Write-Host -ParameterFilter {$object -eq "TIP: test"} -Verifiable 
    
    if($type) {
        $script:result = &(gmo psgit){WriteMessage -type test -message $message -InformationVariable information -InformationAction SilentlyContinue;$information }
    } else {
        $script:result = &(gmo psgit){WriteMessage -type Tip -message test  SilentlyContinue; $information }
    }
}
#>

When "WriteMessage is called" {
    Mock Write-Host {return "TIP: test"} -ParameterFilter {$object -eq "TIP: test"} -Verifiable -ModuleName psgit
    $script:result = &(gmo psgit){WriteMessage -type Tip -message test  }
}

When 'ConvertColor is called' {
        $script:result = &(gmo psgit){ConvertColor -color red }
}

