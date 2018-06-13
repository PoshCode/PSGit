Feature: Get a list of changes to the repository
    In order to understand the history of our repository
    We should have a command that will return the most recent commits

    # This is a freebie, so that there's something not @wip
    Scenario: There's no Repository
        Given we are NOT in a repository
        When Get-GitLog is called
        Then the output should be a warning: "The path is not in a git repository!"

    Scenario: Empty Repository
        Given we have initialized a repository
        When Get-GitLog is called
        Then there should be no output1


    Scenario: Get-GitLog should have similar parameters to git status
        Given we have a command Get-GitChange
        Then it should have parameters:
            | Name           | Type     |
            | PathSpec       | String[] |
            | HideUntracked  | Switch   |
            | ShowIgnored    | Switch   |
            | HideSubmodules | Switch   |
