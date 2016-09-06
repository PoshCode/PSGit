Feature: Get a list of file changes
    In order to customize our command prompts,
    The one thing we absolutely must have as objects is the status
    We will have three commands for this:
    Get-GitChange, Get-Info, and Show-Status (which will wrap the other two)

    # This is a freebie, so that there's something not @wip
    Scenario: There's no Repository
        Given we are NOT in a repository
        When Get-GitChange is called
        Then the output should be a warning: "The path is not in a git repository!"

    Scenario: Get-GitChange should have similar parameters to git status
        Given we have a command Get-GitChange
        Then it should have parameters:
            | Name           | Type     |
            | PathSpec       | String[] |
            | HideUntracked  | Switch   |
            | ShowIgnored    | Switch   |
            | HideSubmodules | Switch   |

    Scenario: Get-GitChange should allow fetching only un/staged changes
        Given we have a command Get-GitChange
        Then it should have parameters:
            | Name         | Type   |
            | UnstagedOnly | Switch |
            | StagedOnly   | Switch |

    Scenario: Empty Repository
        Given we have initialized a repository
        When Get-GitChange is called
        Then there should be no output

    Scenario: New Files in Repository
        Given we have initialized a repository with
            | FileAction | Name          |
            | Created    | FileOne.ps1   |
            | Created    | FileTwo.ps1   |
            | Created    | FileThree.ps1 |
        When Get-GitChange is called
        Then the status of git should be
            | Staged | Change | Path          |
            | False  | Added  | FileOne.ps1   |
            | False  | Added  | FileThree.ps1 |
            | False  | Added  | FileTwo.ps1   |
 
    Scenario: Added Files to Stage
        Given we have initialized a repository with
            | FileAction | Name          |
            | Created    | FileOne.ps1   |
            | Created    | FileTwo.ps1   |
            | Created    | FileThree.ps1 |
            | Added      | *             |
        When Get-GitChange is called
        Then the status of git should be
            | Staged | Change | Path          |
            | True   | Added  | FileOne.ps1   |
            | True   | Added  | FileThree.ps1 |
            | True   | Added  | FileTwo.ps1   |
 
    Scenario: Added and Modified Files
        Given we have initialized a repository with
            | FileAction | Name          |
            | Created    | FileOne.ps1   |
            | Created    | FileTwo.ps1   |
            | Created    | FileThree.ps1 |
            | Added      | *             |
            | Modified   | FileOne.ps1   |
            | Modified   | FileThree.ps1 |
        When Get-GitChange is called
        Then the status of git should be
            | Staged | Change   | Path          |
            | True   | Added    | FileOne.ps1   |
            | True   | Added    | FileThree.ps1 |
            | True   | Added    | FileTwo.ps1   |
            | False  | Modified | FileOne.ps1   |
            | False  | Modified | FileThree.ps1 |
        When Get-GitChange -Staged is called
        Then the status of git should be
            | Staged | Change | Path          |
            | True   | Added  | FileOne.ps1   |
            | True   | Added  | FileTwo.ps1   |
            | True   | Added  | FileThree.ps1 |
        When Get-GitChange -Unstaged is called
        Then the status of git should be
            | Staged | Change   | Path          |
            | False  | Modified | FileOne.ps1   |
            | False  | Modified | FileThree.ps1 |

    Scenario: Added, Commited and Modified Files
        Given we have initialized a repository with
            | FileAction | Name           |
            | Created    | FileOne.ps1    |
            | Created    | FileTwo.ps1    |
            | Added      | *              |
            | Commited   | Initial Commit |
            | Modified   | FileOne.ps1    |
            | Added      | *              |
            | Modified   | FileTwo.ps1    |
            | Created    | FileThree.ps1  |
            | Modified   | FileThree.ps1  |
        When Get-GitChange is called
        Then the status of git should be
            | Staged | Change   | Path          |
            | True   | Modified | FileOne.ps1   |
            | False  | Modified | FileTwo.ps1   |
            | False  | Added    | FileThree.ps1 |
 
    Scenario: Removed Files
        Given we have initialized a repository with
            | FileAction | Name           |
            | Created    | FileOne.ps1    |
            | Created    | FileTwo.ps1    |
            | Added      | *              |
            | Commited   | Initial Commit |
            | Removed    | FileOne.ps1    |
            | Added      | *              |
            | Removed    | FileTwo.ps1    |
        When Get-GitChange is called
        Then the status of git should be
            | Staged | Change  | Path        |
            | True   | Removed | FileOne.ps1 |
            | False  | Removed | FileTwo.ps1 |
 
    Scenario: Renamed Files
        Given we have initialized a repository with
            | FileAction | Name           | Value     |
            | Created    | FileOne.ps1    |           |
            | Created    | FileTwo.ps1    |           |
            | Created    | FileThree.ps1  |           |
            | Added      | *              |           |
            | Commited   | Initial Commit |           |
            | Renamed    | FileOne.ps1    | File1.ps1 |
            | Renamed    | FileThree.ps1  | File3.ps1 |
            | Added      | *              |           |
            | Modified   | File3.ps1      |           |
            | Renamed    | FileTwo.ps1    | File2.ps1 |
        When Get-GitChange is called
        Then the status of git should be
            | Staged | Change   | Path      | OldPath       |
            | True   | Renamed  | File1.ps1 | FileOne.ps1   |
            | True   | Renamed  | File3.ps1 | FileThree.ps1 |
            | False  | Renamed  | File2.ps1 | FileTwo.ps1   |
            | False  | Modified | File3.ps1 |               |
 
    Scenario: Ignored Files
        Given we have initialized a repository with
            | FileAction | Name        | Value |
            | Created    | FileOne.ps1 |       |
            | Created    | FileTwo.ps1 |       |
            | Ignore     | FileOne.ps1 |       |
        When Get-GitChange -ShowIgnored is called
        Then the status of git should be
            | Staged | Change  | Path        |
            | False  | Added   | FileTwo.ps1 |
            | False  | Ignored | FileOne.ps1 |

    Scenario: Submodules
        Given we have initialized a repository with
            | FileAction | Name        | Value |
            | Created    | FileOne.ps1 |       |
        And we have added a submodule "module"
        When Get-GitChange is called
        Then the status of git should be
            | Staged | Change | Path        |
            | True   | Added  | .gitmodules |
            | True   | Added  | module\     |
            | False  | Added  | FileOne.ps1 |
        When Get-GitChange -HideSubmodules is called
        Then the status of git should be
            | Staged | Change | Path        |
            | True   | Added  | .gitmodules |
            | False  | Added  | FileOne.ps1 |

    Scenario: Show-GitStatus calls both Get-GitInfo and Get-GitChange
        Given we have initialized a repository with
            | FileAction | Name           | Value     |
            | Created    | FileOne.ps1    |           |
            | Created    | FileTwo.ps1    |           |
            | Created    | FileThree.ps1  |           |
            | Added      | *              |           |
            | Commited   | Initial Commit |           |
            | Renamed    | FileOne.ps1    | File1.ps1 |
            | Renamed    | FileThree.ps1  | File3.ps1 |
            | Added      | *              |           |
            | Created    | File4.ps1      |           |
            | Modified   | File3.ps1      |           |
            | Renamed    | FileTwo.ps1    | File2.ps1 |
        And we expect Get-Info and Get-Change to be called
        When Show-GitStatus is called
        Then Get-Info is logged exactly 1 time
        And Get-Change is logged exactly 1 time
