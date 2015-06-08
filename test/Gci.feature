Feature: Get-ChildItem proxy function
    This will test the functionality of the gci proxy to make sure the output is correctly modified
    
    Scenario: GCI not in a repo
        Given we are NOT in a repository with
            | FileAction | Name          |
            | Created    | FileOne.ps1   |
        When Get-ChildItem is called
        Then the resulting object should not have a Changed property

    Scenario: GCI in a repo
        Given we have initialized a repository with
            | FileAction | Name          |
            | Created    | FileOne.ps1   |
            | Added      | FileOne.ps1   |
            | Created    | FileTwo.ps1   |
        When Get-ChildItem is called
        Then the resulting object should have a Changed property