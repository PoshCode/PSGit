@wip
Feature: Commit staged changes to the Repository
	As a PowerShell user
	I want to save the changes I made in my repository
	So that I can restore a previous state of my work whenever I need to

	Scenario: Save-Change should have similar paramteres as git commit
		Given we have a command Save-Change
		Then it should have parameters:
			| Name                                   | Type     |
			| Message                                | String[] |
			| CopyAuthorshipAndMessageFromChange     | String   |
			| CopyAuthorshipAndEditMessageFromChange | String   |
			| MessageTemplate                        | String   |
			| Author                                 | String   |
			| ModifyLastSavedChange                  | Switch   |
			| EditMessage                            | Switch   |
			| KeepMessage                            | Switch   |
			
		# -Message maps to -m/--message
		# -CopyAuthorshipAndMessageFromChange maps to -C/--reuse-message
		# -CopyAuthorshipAndEditMessageFromChange maps to -c/reedit-message
		# -MessageTemplate maps to -t/--template
		# -Author maps to --author
		# -EditMessage maps to -e/--edit
		# -KeepMessage maps to --no-edit
		# ignoring pathspecs, --all, --patch, --fixup, --squash, --reset-author, 
		#   --signoff,  --no-verify, --allow-empty, --allow-empty-message, 
		#   --no-post-rewrite, --include, --gpg-sign, --no-gpg-sign, -F/--file for the time being
		# pathspec will not be provided with PSGit. Any selection of what to commit should be done using Add-Change instead

	@wip
	Scenario: Commit all staged changes
		Given we have a repository with
		| ChangeState | FileName             |
		| staged      | stagedFile.txt       |
		| staged      | other/stagedFile.txt |
		| modified    | modifiedFile.txt     |
		When I call Save-Change -Message "Saving all staged changes"
		Then the output shows a summary line for the saved change
		And the summary line contains the branch name, 
		And the summary line contains the short commit id 
		And the summary line contains the commit message
		And the status info shows
		| ChangeState | FileName         |
		| modified    | modifiedFile.txt |

	@wip
	Scenario: Commit with a multipart message
		Given we have a repository with
		| ChangeState | FileName             |
		| staged      | stagedFile.txt       |
		| staged      | other/stagedFile.txt |
		| modified    | modifiedFile.txt     |
		When I call Save-Change -Message "Saving all staged changes" "with additional message text"
		Then the output shows a summary line for the saved change
		And the summary line contains the branch name, 
		And the summary line contains the short commit id 
		And the summary line contains the commit message
		And the status info shows
		| ChangeState | FileName         |
		| modified    | modifiedFile.txt |
		And the status info shows both parts of the commit message as individual paragraphs
	
	@wip
	Scenario: Use an editor to enter a commit message
		Given we have a repository with
		| ChangeState | FileName             |
		| staged      | stagedFile.txt       |
		| staged      | other/stagedFile.txt |
		| modified    | modifiedFile.txt     |
		And I have configured notepad as my default editor for git
		When I call Save-Change
		Then notepad is opened for entering a commit message
	
	@wip
	Scenario: Use a template for generating a commit message
		Given we have a repository with
		| ChangeState | FileName             |
		| staged      | stagedFile.txt       |
		| staged      | other/stagedFile.txt |
		| modified    | modifiedFile.txt     |
		And I have configured notepad as my default editor for git
		And I have configured a template.commitmsg as message template
		When I call Save-Change -MessageTemplate
		Then notepad is opened for entering a commit message
		And the content of template.commitmsg is displayed
	
	@wip
	Scenario: supply author information for saving the change
		Given we have a repository with
		| ChangeState | FileName             |
		| staged      | stagedFile.txt       |
		| staged      | other/stagedFile.txt |
		| modified    | modifiedFile.txt     |
		When I call Save-Change -Message "using different author info" -Author "A U Thor <author@example.com>"
		Then the output shows a summary line for the saved change
		And the summary line contains the branch name
		And the summary line contains the short commit id 
		And the summary line contains the commit message
		And the summary line shows A U Thor as the author of the saved change
		And the status info shows
		| ChangeState | FileName         |
		| modified    | modifiedFile.txt |

	@wip
	Scenario: use the commit message from a previous commit
		Given we have a repository with
		| Commit | Message                    | Author                        |
		| First  | Initial Commit             | John Doe <J.Doe@unknown.com>  |
		| Second | Grandparent commit message | A U Thor <author@example.com> |
		| Third  | Parent commit message      | Jane Doe <JaneD@unkown.com>   |
		When I call Save-Change -CopyAuthorshipAndMessageFromChange HEAD~2
		Then the output shows a summary line for the saved change
		And the summary line contains the branch name
		And the summary line contains the short commit id 
		And the summary line contains the commit message of the Second commit
		And the summary line shows A U Thor as the author of the saved change

	@wip
	Scenario: use and edit the commit message from a previous commit
		Given we have a repository with
		| Commit | Message                    | Author                        |
		| First  | Initial Commit             | John Doe <J.Doe@unknown.com>  |
		| Second | Grandparent commit message | A U Thor <author@example.com> |
		| Third  | Parent commit message      | Jane Doe <JaneD@unkown.com>   |
		And I have configured notepad as my default editor for git
		When I call Save-Change -CopyAuthorshipAndEditMessageFromChange HEAD~2
		Then notepad is opened for entering a commit message
		And the commit message from the Second commit is displayed for editing
		
	@wip
	Scenario: amend the the previous commit and keep the message as it is
		Given we have a repository with
		| Commit | Message                    | Author                        |
		| First  | Initial Commit             | John Doe <J.Doe@unknown.com>  |
		| Second | Grandparent commit message | A U Thor <author@example.com> |
		| Third  | Parent commit message      | Jane Doe <JaneD@unkown.com>   |
		When I call Save-Change -ModifyLastSavedChange -KeepMessage
		Then the output shows a summary line for the saved change
		And the summary line contains the branch name
		And the summary line contains the short commit id 
		And the summary line contains the commit message of the Third commit
		
	@wip
	Scenario: amend the the previous commit and edit the message
		Given we have a repository with
		| Commit | Message                    | Author                        |
		| First  | Initial Commit             | John Doe <J.Doe@unknown.com>  |
		| Second | Grandparent commit message | A U Thor <author@example.com> |
		| Third  | Parent commit message      | Jane Doe <JaneD@unkown.com>   |
		And I have configured notepad as my default editor for git
		When I call Save-Change -ModifyLastSavedChange -EditMessage
		Then notepad is opened for entering a commit message
		And the commit message from the Second commit is displayed for editing