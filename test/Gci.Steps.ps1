BeforeScenario {
    $script:repo = Convert-Path TestDrive:\
    Push-Location TestDrive:\
    [Environment]::CurrentDirectory = $repo
    Remove-Item TestDrive:\* -Recurse -Force
}

AfterScenario {
    Pop-Location
    [Environment]::CurrentDirectory = Convert-Path $Pwd
}

When 'Get-ChildItem is called' {
    $script:result = Get-ChildItem
}

When 'Get-ChildItem -outbuffer 5 is called' {
    $script:result = Get-ChildItem -outbuffer 5
}

Then 'the resulting object should not have a Changed property' {

    if($script:result | get-member -membertype noteproperty | ? name -eq Change) {
        throw "Found Property, showing Git status when we are not in a repo"
    }
}

Then 'the resulting object should have a Changed property' {

    if($script:result | get-member -membertype noteproperty | ? name -eq Change) {
        
    }
    else {
        throw "Property not found!"
    }
}