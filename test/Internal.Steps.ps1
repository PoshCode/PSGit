When "WriteMessage ((?<type>\S+)\s+(?<message>\S+))? ?is called" {
    param($type,$message)
    if($type) {
        $script:result = &(gmo psgit){WriteMessage -type test -message $message -InformationVariable information -InformationAction SilentlyContinue;$information }
    } else {
        $script:result = &(gmo psgit){WriteMessage -type Tip -message test  -InformationVariable information -InformationAction SilentlyContinue; $information }
    }
}

When 'ConvertColor is called' {
        $script:result = &(gmo psgit){ConvertColor -color red }
}