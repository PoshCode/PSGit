Feature: Get current repository status
    Most of git we could use from the old git binary commands, however
    In order to customize our command prompts,
    The one thing we absolutely must have as objects is the status
    The command name will get Get-GitStatus

    # This is a freebie, so that there's something not @wip
    Scenario: There's no Repository
        Given we are NOT in a repository
        When Get-GitStatus is called
        Then the output should be: "The path is not in a git repository!"

    @wip
    Scenario: Get-GitStatus should have similar parameters to git status
        Given we have a command Get-GitStatus
        Then it should have parameters:
            | Name           | Type   |
            | Path           | String |

    @wip
    Scenario: Empty Repository
        Given we have initialized a repository
        When Get-GitStatus is called
        Then the output should have
            | Property | Value             |
            | Branch   | master            |
            | Summary  | Nothing to commit |
            | Note     | Initial Commit    |

    @wip
    Scenario: New Files in Repository
        Given we have initialized a repository with
            | FileAction | Name          |
            | Created    | FileOne.ps1   |
            | Created    | FileTwo.ps1   |
            | Created    | FileThree.ps1 |
        When Get-GitStatus is called
        Then the output should have
            | Property | Value             |
            | Branch   | master            |
            | Summary  | Nothing to commit |
            | Note     | Initial Commit    |
        And the count of changes should be
            | State     | Count |
            | Untracked | 3     |
        And the 3 untracked file names should be available

    @wip
    Scenario: Added Files to Stage
        Given we have initialized a repository with
            | FileAction | Name          |
            | Created    | FileOne.ps1   |
            | Created    | FileTwo.ps1   |
            | Created    | FileThree.ps1 |
            | Added      | *             |
        When Get-GitStatus is called
        Then the output should have
            | Property | Value          |
            | Branch   | master         |
            | Summary  | 3 Added        |
            | Note     | Initial Commit |
        And the count of changes should be
            | State | Count |
            | Added | 3     |
        And the 3 added file names should be available

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
        Then the output should have
            | Property | Value               |
            | Branch   | master              |
            | Summary  | 3 Added, 2 Modified |
            | Note     | Initial Commit      |
        And the count of changes should be
            | State          | Count |
            | Added          | 1     |
            | Added,Modified | 2     |
        And the 3 added file names should be available
        And the 2 modified file names should be available

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
        Then the output should have
            | Property | Value                   |
            | Branch   | master                  |
            | Summary  | 1 Modified, 1 Untracked |
        And the count of changes should be
            | State     | Count |
            | Untracked | 1     |
            | Modified  | 1     |
        And the 1 untracked file name should be available
        And the 1 modified file name should be available

