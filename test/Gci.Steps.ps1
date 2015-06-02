When 'Get-ChildItem is called' {
    $script:repo = Convert-Path TestDrive:\
    Push-Location TestDrive:\
    [Environment]::CurrentDirectory = $repo
    $script:result = Get-ChildItem
}


Then 'the resulting object should not have a Changed property' {

    if($script:result | get-member -membertype noteproperty | ? name -eq Changed) {
        throw "Found Property, showing Git status when we are not in a repo"
    }
}

Then 'the resulting object should have a Changed property' {

    if($script:result | get-member -membertype noteproperty | ? name -eq Changed) {
        
    }
    else {
        throw "Property not found!"
    }
}