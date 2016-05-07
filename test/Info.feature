Feature: Get repository status
    In order to customize our command prompts,
    And know if what branch we're on, and whether changes have been made upstream
    We need a Get-Info command which returns information about the repository and its remotes

    Scenario: There's no Repository
        Given we are NOT in a repository
        When Get-GitInfo is called
        Then the output should be a warning: "The path is not in a git repository!"

    Scenario: Empty Repository
        Given we have initialized a repository
        When Get-GitInfo is called
        Then the output should have
            | Property | Value   |
            | Branch   | master  |
            | Ahead    | $null   |
            | Behind   | $null   |

    Scenario: Local Repository with commits and modified Files
        Given we have initialized a repository with
            | FileAction | Name           |
            | Created    | FileOne.ps1    |
            | Created    | FileTwo.ps1    |
            | Added      | *              |
            | Commited   | Simple Edit    |
            | Modified   | FileOne.ps1    |
            | Created    | FileThree.ps1  |
            | Modified   | FileThree.ps1  |
        When Get-GitInfo is called
        Then the output should have
            | Property | Value   |
            | Branch   | master  |
            | Ahead    | $null   |
            | Behind   | $null   |

    Scenario: Cloned Repository with commits and Modified Files
        Given we have cloned a repository and
            | FileAction | Name           |
            | Created    | FileOne.ps1    |
            | Created    | FileTwo.ps1    |
            | Added      | *              |
            | Commited   | Simple Edit    |
            | Modified   | FileOne.ps1    |
            | Created    | FileThree.ps1  |
            | Modified   | FileThree.ps1  |
        When Get-GitInfo is called
        Then the output should have
            | Property | Value  |
            | Branch   | master |
            | Ahead    | 1      |
            | Behind   | 0      |

    Scenario: Cloned Repository with multiple commits
        Given we have cloned a repository and
            | FileAction | Name           |
            | Created    | FileOne.ps1    |
            | Added      | *              |
            | Commited   | New File       |
            | Modified   | FileOne.ps1    |
            | Added      | *              |
            | Commited   | Simple Edit    |
            | Created    | FileThree.ps1  |
            | Modified   | FileThree.ps1  |
            | Added      | *              |
            | Commited   | New Third File |
        When Get-GitInfo is called
        Then the output should have
            | Property | Value  |
            | Branch   | master |
            | Ahead    | 3      |
            | Behind   | 0      |

    Scenario: Push and commit more
        Given we have cloned a repository and
            | FileAction | Name           |
            | Created    | FileOne.ps1    |
            | Added      | *              |
            | Commited   | Add File One   |
            | Push       |                |
            | Modified   | FileOne.ps1    |
            | Added      | *              |
            | Commited   | Edit File One  |
            | Created    | FileThree.ps1  |
            | Modified   | FileThree.ps1  |
            | Added      | *              |
            | Commited   | Add File Three |
        When Get-GitInfo is called
        Then the output should have
            | Property | Value  |
            | Branch   | master |
            | Ahead    | 2      |
            | Behind   | 0      |

    Scenario: Upstream Changes 
        Given we have cloned a repository and
            | FileAction | Name           |
            | Created    | FileOne.ps1    |
            | Added      | *              |
            | Commited   | Add File One   |
            | Push       |                |
            | Reset      | HEAD~1         |
        When Get-GitInfo is called
        Then the output should have
            | Property | Value  |
            | Branch   | master |
            | Ahead    | 0      |
            | Behind   | 1      |

    Scenario: Upstream changes and local changes
        Given we have cloned a repository and
            | FileAction | Name           |
            | Created    | FileOne.ps1    |
            | Added      | *              |
            | Commited   | Add File One   |
            | Push       |                |
            | Reset      | HEAD~1         |
            | Created    | FileTwo.ps1    |
            | Added      | *              |
            | Commited   | Add File Two   |
        When Get-GitInfo is called
        Then the output should have
            | Property | Value  |
            | Branch   | master |
            | Ahead    | 1      |
            | Behind   | 1      |
