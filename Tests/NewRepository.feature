Feature: Initialize a blank repository
    Before we can do anything with git, we need a git repository to work in.
    We need a New-Repository command to create blank git repositories.


    Scenario: There's no Repository
        Given we are in an empty folder
        When New-GitRepository is called
        When Get-GitInfo is called
        Then the output should have
            | Property | Value          |
            | Branch   | master         |
        And there should be a "./.git/refs/heads" folder
        And there should be a "./.git/refs/tags" folder
        And there should be a "./.git/objects" folder
        And there should NOT be a "./.git/refs/heads/master" file
        And the content of "./.git/HEAD" should be "ref: refs/heads/master"

    # Reinitializing a repository basically just copies new templates, but I don't know anything about that.

    Scenario: There's an existing Repository
        Given we are in a git repository
        When New-GitRepository is called
        When Get-GitInfo is called
        Then there should be a "./.git/refs/heads" folder
        And there should be a "./.git/refs/tags" folder
        And there should be a "./.git/objects" folder


    Scenario: New-GitRepository should have similar parameters to git init
        Given we have a command New-GitRepository
        Then it should have parameters:
            | Name | Type   |
            | Root | String |
