Feature: Add changes to a repo
	In order to track changes with Git, 
	changes need to be added to the staging area a.k.a. the index
	That's what Add-Change does.

@wip
Scenario: Add-Change should have similar parameters to git add
	Given we have a command Add-Change
	Then it should have parameters:
		| Name     | Type     |
		| PathSpec | String[] |
		| Force    | Switch   |
		| Update   | Switch   |
		| All      | Switch   |
		| NoRemove | Switch   |
# -Force could also be called -IncludeIgnored since that is it's only purpose
# -NoRemove translates to --no-all
# ignoring  --intent-to-add, --refresh, --interactive, --patch, --edit for the time being
# -ErrorAction Continue translates to --ignore-errors, but that would be default
# -WhatIf translates to --dry-run
# -Verbose translates to -verbose (duh)
# Do you normally also list the common parameters (WhatIf, Verbose, ErrorAction) here? 

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
	Then the status info should show that there are changes on the current branch
	And the changes are in a file that is added to the staging area
	And the added file is called NewFile.txt

# This is somewhat similar to Ignored Files from Changes.feature
@wip
Scenario: stage a change in an ignored file
	Given we have initialized a repository by running New-Repository
	And the .gitignore file contains the glob *.ignored
	When Add-Change ToBe.ignored is called
	Then nothing changes
	When Add-Change ToBe.ignored -Force is called
	Then the status info should show that there are changes on the current branch
	And the changes are in a new file added to the staging area
	And the added file is called ToBe.ignored

# This is the same as Added and Modified files from Changes.feature, but using Add-Change to add files tot he index
@wip
Scenario: add more changes to an existing change in the staging area
	Given we have a repository with
		| ChangeState | FileName         |
		| Committed   | TrackedFile.txt  |
		| Committed   | FileToDelete.txt |
	And there is an untracked file NewFile.txt in the working directory
	And FileToDelete.txt is deleted from the working directory
	And there is a modified version of TrackedFile.txt in the working directory
	When Add-Change -Update is called
	Then the status info should show that there are changes on the current branch
		| ChangeState | FileName         |
		| modified    | TrackedFile.txt  |
		| deleted     | FileToDelete.txt |
		| untracked   | NewFile.txt      |
	
@wip
Scenario: add more changes to the staging area
	Given we have a repository with
		| ChangeState | FileName         |
		| Committed   | TrackedFile.txt  |
		| Committed   | FileToDelete.txt |
	And there is an untracked file called NewFile.txt in the working directory
	And I have deleted FileToDelete.txt from the working directory
	When I change the content of TrackedFile.txt in the working directory
	And Add-Change -All is called
	Then the status info should show that there are changes on the current branch
		| ChangeState | FileName        |
		| modified    | TrackedFile.txt |
		| added       | NewFile.txt     |
	And the file FileToDelete.txt was removed from the staging area
	
@wip
Scenario: add more changes to the staging area but remove nothing
	Given we have a repository with
		| ChangeState | FileName         |
		| Committed   | TrackedFile.txt  |
		| Committed   | FileToDelete.txt |
	And there is an untracked file called NewFile.txt in the working directory
	And I have deleted FileToDelete.txt from the working directory
	When I change the content of TrackedFile.txt in the working directory
	And Add-Change -NoDelete is called
	Then the status info should show that there are changes on the current branch
		| ChangeState | FileName        |
		| modified    | TrackedFile.txt |
		| added       | NewFile.txt     |
