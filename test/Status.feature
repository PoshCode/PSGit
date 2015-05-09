Feature: Get a list of file changes
    In order to customize our command prompts,
    The one thing we absolutely must have as objects is the status
    We will have three commands for this:
    Get-Status, Get-Info, and Show-Status (which will wrap the other two)

    # This is a freebie, so that there's something not @wip
    Scenario: There's no Repository
        Given we are NOT in a repository
        When Get-GitStatus is called
        Then the output should be a warning: "The path is not in a git repository!"

    @wip
    Scenario: Get-GitStatus should have similar parameters to git status
        Given we have a command Get-GitStatus
        Then it should have parameters:
            | Name           | Type   |
            | Path           | String |

    @wip
    Scenario: Get-GitStatus should allow fetching only unstaged changes
        Given we have a command Get-GitStatus
        Then it should have parameters:
            | Name         | Type   |
            | UnstagedOnly | Switch |

    @wip
    Scenario: Empty Repository
        Given we have initialized a repository
        When Get-GitStatus is called
        Then there should be no output

    @wip
    Scenario: New Files in Repository
        Given we have initialized a repository with
            | FileAction | Name          |
            | Created    | FileOne.ps1   |
            | Created    | FileTwo.ps1   |
            | Created    | FileThree.ps1 |
        When Get-GitStatus is called
        Then the status of git should be
            | Staged | Change | Name          |
            | False  | Added  | FileOne.ps1   |
            | False  | Added  | FileTwo.ps1   |
            | False  | Added  | FileThree.ps1 |
 
    @wip
    Scenario: Added Files to Stage
        Given we have initialized a repository with
            | FileAction | Name          |
            | Created    | FileOne.ps1   |
            | Created    | FileTwo.ps1   |
            | Created    | FileThree.ps1 |
            | Added      | *             |
        When Get-GitStatus is called
        Then the status of git should be
            | Staged | Change | Name          |
            | True   | Added  | FileOne.ps1   |
            | True   | Added  | FileTwo.ps1   |
            | True   | Added  | FileThree.ps1 |
 
    @wip
    Scenario: Added and Modified Files
        Given we have initialized a repository with
            | FileAction | Name          |
            | Created    | FileOne.ps1   |
            | Created    | FileTwo.ps1   |
            | Created    | FileThree.ps1 |
            | Added      | *             |
            | Modified   | FileOne.ps1   |
            | Modified   | FileThree.ps1 |
        When Get-GitStatus is called
        Then the status of git should be
            | Staged | Change   | Name          |
            | True   | Added    | FileOne.ps1   |
            | True   | Added    | FileTwo.ps1   |
            | True   | Added    | FileThree.ps1 |
            | False  | Modified | FileThree.ps1 |
            | False  | Modified | FileOne.ps1   |
 
    @wip
    Scenario: Added, Commited and Modified Files
        Given we have initialized a repository with
            | FileAction | Name           |
            | Created    | FileOne.ps1    |
            | Created    | FileTwo.ps1    |
            | Added      | *              |
            | Commited   | Initial Commit |
            | Modified   | FileOne.ps1    |
            | Created    | FileThree.ps1  |
            | Modified   | FileThree.ps1  |
        When Get-GitStatus is called
        Then the status of git should be
            | Staged | Change   | Name          |
            | False  | Modified | FileTwo.ps1   |
            | False  | Added    | FileThree.ps1 |
 
