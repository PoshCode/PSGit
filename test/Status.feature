Feature: Get current repository status
    Most of git we could use from the old git binary commands, however
    In order to customize our command prompts, 
    The one thing we absolutely must have as objects is the status
    The command name will get Get-GitStatus

    Scenario: Empty Repository
        Given a new repository
        When Get-GitStatus is called
        Then the returned object should show
            | Property | Value             |
            | Branch   | master            |
            | Summary  | Nothing to commit |
            | Note     | Initial Commit    |

    Scenario: New Files in Repository
        Given a new repository
        And adding 3 files
        When Get-GitStatus is called
        Then the returned object should show
            | Property   | Value             |
            | Branch     | master            |
            | Summary    | Nothing to commit |
            | Note       | Initial Commit    |
            | UntrackedCount | 3             |
        And the 3 untracked file names should be available

    Scenario: Added Files to Stage
        Given a new repository
        And adding 3 files
        When Add-GitItem * is called
        When Get-GitStatus is called
        Then the returned object should show
            | Property   | Value             |
            | Branch     | master            |
            | Summary    | Nothing to commit |
            | Note       | Initial Commit    |
            | AddedCount | 3                 |
        And the 3 added file names should be available

    Scenario: Added and Modified Files
        Given a new repository
        And adding 3 files
        When Add-GitItem * is called
        And 2 files are edited
        When Get-GitStatus is called
        Then the returned object should show
            | Property   | Value             |
            | Branch     | master            |
            | Summary    | Nothing to commit |
            | Note       | Initial Commit    |
            | AddedCount | 3                 |
            | ModifiedCount | 2              |
        And the 3 added file names should be available
        And the 2 moddified file names should be available
