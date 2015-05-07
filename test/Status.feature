Feature: Get current repository status
    Most of git we could use from the old git binary commands, however
    In order to customize our command prompts, 
    The one thing we absolutely must have as objects is the status
    The command name will get Get-Status


    Scenario: Empty Repository
        Given a new repository
        When Get-Status is called
        Then the returned object should show
            | Branch | Summary           | Note           | 
            | master | Nothing to commit | Initial Commit |