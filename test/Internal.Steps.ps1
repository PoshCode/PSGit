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
Given "we have WPF loaded" {
    Add-Type -AssemblyName presentationCore
}
When "WriteMessage ((?<type>\S+)\s+(?<message>\S+)) is called" {
param($type,$message)

    Mock Write-Host {"$($type.toupper()): $message"}  -Verifiable -ModuleName psgit
    $script:result = &(gmo psgit){WriteMessage -type $args[0] -message $args[1]} $type $message
}

When 'ConvertColor (?<color>\S+) is called' {
param($color)
    $script:result = &(gmo psgit){ConvertColor -color "$args" } "$color"
}

