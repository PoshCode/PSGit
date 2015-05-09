Feature: Get repository status
    In order to customize our command prompts,
    And know if what branch we're on, and whether changes have been made upstream
    We need a Get-Info command which returns information about the repository and its remotes

    Scenario: There's no Repository
        When Get-GitInfo is called
        Then the output should be a warning: "The path is not in a git repository!"

    @wip
    Scenario: Empty Repository
        Given we have initialized a repository
        When Get-GitInfo is called
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
        When Get-GitInfo is called
        Then the output should have
            | Property | Value             |
            | Branch   | master            |
            | Summary  | Nothing to commit |
            | Note     | Initial Commit    |

    @wip
    Scenario: Added Files to Stage
        Given we have initialized a repository with
            | FileAction | Name          |
            | Created    | FileOne.ps1   |
            | Created    | FileTwo.ps1   |
            | Created    | FileThree.ps1 |
            | Added      | *             |
        When Get-GitInfo is called
        Then the output should have
            | Property | Value          |
            | Branch   | master         |
            | Summary  | 3 Added        |
            | Note     | Initial Commit |

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
        When Get-GitInfo is called
        Then the output should have
            | Property | Value               |
            | Branch   | master              |
            | Summary  | 3 Added, 2 Modified |
            | Note     | Initial Commit      |

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

