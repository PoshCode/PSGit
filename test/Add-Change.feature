Feature: Add changes to a repo
	In order to track changes with Git, 
	changes need to be added to the repository
	That's what Add-Change does.

@wip
Scenario: There's no repository
	Given we are NOT in a repository
	When Add-Change is called
	Then the output should be a warning: "The path is not in a git repository!"

@wip
Scenario: Add-Change should have similar parameters to git add
	Given we have a command Add-Change
	Then it should have parameters:
		| Name      | Type     |
		| PathSpec  | String[] |
		| Force     | Switch   |
		| Update    | Switch   |
		| UpdateAll | Switch   |
# -Force could also be called -IncludeIgnored since that is it's only purpose
# Do you normally also list the common parameters here? (e.g. WhatIf, Verbose,...)


#This is the same as Added Files to Stage from Changes.feature, but using Add-Change to add the files to the index
@wip
Scenario: add an untracked file
	Given we have initialized a repository
	And there is an untracked file called NewFile.txt
	When Add-Change NewFile.txt is called
	Then the status info should show that there are changes on the current branch
	And the changes are in a new file added to the index
	And the added file is called NewFile.txt

# This is somewhat similar to Ignored Files from Changes.feature
@wip
Scenario: add an ignored file to the index
	Given we have initialized  a repository
	And the .gitignore file lists the glob *.ignored
	When Add-Change ToBe.ignored is called
	Then nothing changes
	When Add-Change ToBe.ignored -Force is called
	Then the status info should show that there are changes on the current branch
	And the changes are in a new file added to the index
	And the added file is called ToBe.ignored


# This is the same as Added and Modified files from Changes.feature, but using Add-Change to add files tot he index
@wip
Scenario: update a tracked file
	Given we have initialized a repository
	And there is a file called TrackedFile.txt already added to the index
	And there is an untracked file called NewFile.txt
	But TrackedFile.txt is not yet committed
	When I change the content of TrackedFile.txt
	And Add-Change -Update TrackedFile.txt is called
	Then the status info should show that there are changes on the current branch
	And the changes are in a new file added to the index
	And the added file is called TrackedFile.txt
	And there is an untracked file called NewFile.txt
