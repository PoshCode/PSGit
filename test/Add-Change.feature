Feature: Add changes to a repo
	In order to track changes with Git, 
	changes need to be added to the staging area a.k.a. the index
	That's what Add-Change does.

@wip
Scenario: Add-Change should have similar parameters to git add
	Given we have a command Add-Change
	Then it should have parameters:
		| Name				   | Type     |
		| [PathSpec]		   | String[] |
		| IncludeIgnored	   | Switch   |
		| UpdateStagedChanges  | Switch   |
		| All				   | Switch   |
		| IgnoreDeletedChanges | Switch   |
# -IncludeIgnored maps to --force
# -UpdateExisting maps to --update
# -IgnoreDeletedChanges maps to --no-all
# -ErrorAction Continue maps to --ignore-errors, but that would be default
# -WhatIf maps to --dry-run
# -Verbose maps to -verbose (duh)
# Do you normally also list the common parameters (WhatIf, Verbose, ErrorAction) here? 
# ignoring  --intent-to-add, --refresh, --interactive, --patch, --edit for the time being

@wip
Scenario: There's no repository
	Given we are NOT in a repository
	When Add-Change is called
	Then the output should be a warning: "The path is not in a git repository!"

#This is the same as Added Files to Stage from Changes.feature, but using Add-Change to add the files to the index
@wip
Scenario: stage a change in an untracked file
	Given we have initialized a repository by running New-Repository
	And there is an untracked file called NewFile.txt in the working directory
	When Add-Change NewFile.txt is called
	And I ask git for a status
	Then the status info should show that there are changes on the current branch
		| ChangeState | FileName    |
		| added       | NewFile.txt |

# This is somewhat similar to Ignored Files from Changes.feature
@wip
Scenario: stage a change in an ignored file
	Given we have initialized a repository by running New-Repository
	And the .gitignore file contains the glob *.ignored
	When Add-Change ToBe.ignored is called
	And I ask git for a status
	Then the status info should show that nothing changed
	When Add-Change ToBe.ignored -IncludeIgnored is called
	And I ask git for a status
	Then the status info should show that there are changes on the current branch
		| ChangeState | FileName     |
		| added       | ToBe.ignored |

# This is the same as Added and Modified files from Changes.feature, but using Add-Change to add files to the index
@wip
Scenario: add more changes to an existing change in the staging area
	Given we have a repository with
		| ChangeState | FileName         |
		| Committed   | TrackedFile.txt  |
		| Committed   | FileToDelete.txt |
	And there is an untracked file NewFile.txt in a subfolder NewFolder of the working directory
	And FileToDelete.txt is deleted from the working directory
	And there is a modified version of TrackedFile.txt in the working directory
	When Add-Change -UpdateStagedChanges is called
	And I ask git for a status
	Then the status info should show that there are changes on the current branch
		| ChangeState | FileName         |
		| modified    | TrackedFile.txt  |
		| deleted     | FileToDelete.txt |
		| untracked   | NewFolder/NewFile.txt      |
	
@wip
Scenario: add more changes to the staging area
	Given we have a repository with
		| ChangeState | FileName         |
		| Committed   | TrackedFile.txt  |
		| Committed   | FileToDelete.txt |
	And there is an untracked file NewFile.txt in a subfolder NewFolder of the working directory
	And I have deleted FileToDelete.txt from the working directory
	And I have changed the content of TrackedFile.txt in the working directory
	When Add-Change -All is called
	And I ask git for a status
	Then the status info should show that there are changes on the current branch
		| ChangeState | FileName         |
		| modified    | TrackedFile.txt  |
		| added       | NewFolder/NewFile.txt      |
		| deleted     | FileToDelete.txt |

# same as above, but with piping the changes to Add-Change instead of calling -All
@wip
Scenario: add more changes to the staging area
	Given we have a repository with
		| ChangeState | FileName         |
		| Committed   | TrackedFile.txt  |
		| Committed   | FileToDelete.txt |
	And there is an untracked file called NewFile.txt in the working directory
	And I have deleted FileToDelete.txt from the working directory
	And I have changed the content of TrackedFile.txt in the working directory
	When Get-Change | Add-Change is called
	And I ask git for a status
	Then the status info should show that there are changes on the current branch
		| ChangeState | FileName         |
		| modified    | TrackedFile.txt  |
		| added       | NewFile.txt      |
		| deleted     | FileToDelete.txt |
	
@wip
Scenario: add more changes to the staging area but remove nothing
	Given we have a repository with
		| ChangeState | FileName         |
		| Committed   | TrackedFile.txt  |
		| Committed   | FileToDelete.txt |
	And there is an untracked file called NewFile.txt in the working directory
	And I have deleted FileToDelete.txt from the working directory
	And I have changed the content of TrackedFile.txt in the working directory
	When Add-Change -IgnoreDeletedChanges is called
	And I ask git for a status
	Then the status info should show that there are changes on the current branch
		| ChangeState | FileName        |
		| modified    | TrackedFile.txt |
		| added       | NewFile.txt     |
		
@wip
Scenario: add more changes to the staging area and provide verbose output
	Given we have a repository with
		| ChangeState | FileName         |
		| Committed   | TrackedFile.txt  |
		| Committed   | FileToDelete.txt |
	And there is an untracked file called NewFile.txt in the working directory
	And I have deleted FileToDelete.txt from the working directory
	And I have changed the content of TrackedFile.txt in the working directory
	When Add-Change -All -Verbose is called
	Then the output should show that the changes made to the staging area
		| ChangeState | FileName         |
		| modify      | TrackedFile.txt  |
		| add         | NewFile.txt      |
		| delete      | FileToDelete.txt |
	
@wip
Scenario: add more changes to the staging area and provide verbose output
	Given we have a repository with
		| ChangeState | FileName         |
		| Committed   | TrackedFile.txt  |
		| Committed   | FileToDelete.txt |
	And there is an untracked file called NewFile.txt in the working directory
	And I have deleted FileToDelete.txt from the working directory
	And I have changed the content of TrackedFile.txt in the working directory
	When Add-Change -All -WhatIf is called
	Then the output should show that the changes made to the staging area
		| ChangeState | FileName         |
		| modify      | TrackedFile.txt  |
		| add         | NewFile.txt      |
		| delete      | FileToDelete.txt |
	But the changes were not applied to the staging area