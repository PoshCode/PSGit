Feature: Get a list of branches
    In order to customize our command prompts,
    And know if what branch we're on, and whether changes have been made upstream
    We need a Get-Branch command which returns information about branches in the repository and its remotes.


    Scenario: There's no Repository
        Given we are NOT in a repository
        When Get-GitBranch is called
        Then the output should be a warning: "The path is not in a git repository!"

    Scenario: Empty Repository
        Given we have initialized a repository
        When Get-GitBranch is called
        Then the output should have
            | Property  | Value     |
            | Branch    | master    |
            | IsHead    | $True     |
            | IsRemote  | $False    |
            | Tip       | $null     |
            | Remote    | $null     |
            | Ahead     | $null     |
            | Behind    | $null     |

    Scenario: Local Repository with commits
        Given we have initialized a repository with
            | FileAction | Name           |
            | Created    | FileOne.ps1    |
            | Created    | FileTwo.ps1    |
            | Added      | *              |
            | Commited   | Simple Edit    |
        When Get-GitBranch is called
        Then the output should have
            | Property  | Value     |
            | Branch    | master    |
            | IsHead    | $True     |
            | IsRemote  | $False    |
            | Remote    | $null     |
            | Ahead     | $null     |
            | Behind    | $null     |

    Scenario: Cloned Repository with local commits
        Given we have cloned a repository and
            | FileAction | Name           |
            | Created    | FileOne.ps1    |
            | Created    | FileTwo.ps1    |
            | Added      | *              |
            | Commited   | Simple Edit    |
        When Get-GitBranch is called
        Then the output should have
            | Property  | Value     |
            | Branch    | master    |
            | IsHead    | $True     |
            | IsRemote  | $False    |
            | Ahead     | 1         |
            | Behind    | 0         |
        And output 1 'Remote' should match '\.\.\\source'

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
        When Get-GitBranch is called
        Then the output should have
            | Property | Value  |
            | Branch   | master |
            | Ahead    | 3      |
            | Behind   | 0      |

    Scenario: Upstream Changes 
        Given we have cloned a repository and
            | FileAction | Name           |
            | Created    | FileOne.ps1    |
            | Added      | *              |
            | Commited   | Add File One   |
            | Push       |                |
            | Reset      | HEAD~1         |
        When Get-GitBranch is called
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
        When Get-GitBranch is called
        Then the output should have
            | Property | Value  |
            | Branch   | master |
            | Ahead    | 1      |
            | Behind   | 1      |

    Scenario: Upstream branches and local branches
        Given we have cloned a complex repository and
            | FileAction | Name           |
            | Branched   | feature3       |
            | Created    | FileOne.ps1    |
            | Added      | *              |
            | Commited   | Add File One   |
            | Push       |                |
            | Reset      | HEAD~1         |
            | Branched   | feature4       |
            | Created    | FileTwo.ps1    |
            | Added      | *              |
            | Commited   | Add File Two   |
        When Get-GitBranch is called
        Then there should be 3 results
        And output 1 should have
            | Property  | Value     |
            | Branch    | dev       |
            | IsTracking| $True     |
            | IsRemote  | $False    |
        And output 1 'Remote' should match '\.\.\\source'
        And output 2 should have
            | Property  | Value     |
            | Branch    | feature3  |
            | IsTracking| $False    |
            | IsRemote  | $False    |
            | IsHead    | $False    |
            | Remote    | $null     |
        And output 3 should have
            | Property  | Value     |
            | Branch    | feature4  |
            | IsTracking| $False    |
            | IsRemote  | $False    |
            | IsHead    | $True     |
            | Remote    | $null     |

    Scenario: Use -Force to see upstream branches
        Given we have cloned a complex repository
        When Get-GitBranch -Force is called
        Then there should be 6 results
        And output 1 should have
            | Property  | Value     |
            | Branch    | dev       |
            | IsHead    | $True     |
            | IsTracking| $True     |
            | IsRemote  | $False    |
        And output 1 'Remote' should match '\.\.\\source'
        And output 2 should have
            | Property  | Value         |
            | Branch    | origin/HEAD   |
            | IsTracking| $False        |
            | IsRemote  | $True         |
            | IsHead    | $False        |
        And output 2 'Remote' should match '\.\.\\source'
        And output 3 should have
            | Property  | Value         |
            | Branch    | origin/dev    |
            | IsTracking| $False        |
            | IsRemote  | $True         |
            | IsHead    | $False        |
        And output 3 'Remote' should match '\.\.\\source'
        And output 4 'Branch' should eq 'origin/feature1'
        And output 4 'Remote' should match '\.\.\\source'
        And output 5 'Branch' should eq 'origin/feature2'
        And output 5 'Remote' should match '\.\.\\source'
        And output 6 'Branch' should eq 'origin/master'
        And output 6 'Remote' should match '\.\.\\source'
