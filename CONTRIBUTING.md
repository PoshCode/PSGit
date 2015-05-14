## Contributing

Thanks for taking an insterest in contributing to the PowerShell-enabled Git module.

First things first: we assume you have Microsoft's [OneGet "PackageManagement" module](http://OneGet.org) already installed. It is a part of PowerShell 5, but is available downlevel, so what are you waiting for? (**install [this](http://oneget.org/install-oneget.exe)**)?

### Development

Development happens on the **dev** branch. Please send pull requests against that branch only.

The **master** branch contains only features which are _already_ released, and documentation.

We are following the [git flow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) process, but you should not concern yourself with the details too much, just create a feature branch from the **dev** branch, and send your pull request back to dev. _You can refer to [this document](https://guides.github.com/introduction/flow/), except use **dev** instead of master._

This project is organized such that:

* `/src` is the source code of the module itself
* `/test` contains the test code and .feature specifications
* `/lib` contains submodules which point to projects that are required for development.
* `/packages` is not in the repository, but contains (nuget) packages
* `/output` is not in the repository, but is created by the `Build.ps1` scripts for logs and output
* `/1.0` is not in the repository, but is created by the `Build.ps1` script as a _release_ of the module


Thus, all edits to the module code should be in the `/src` folder, and must be tested by tests in the `/test` folder.

Please join our development discussion chat on [PowerShell Slack](https://PowerShell.Slack.com) in the #PowerShell channel. If you're not already a member, you can get an invitation by putting an email address into that first text box on http://slack.poshcode.org/ and clicking `Get-Invite` ;)

### Building Development Versions

To get started, you need to clone the project with the `--recursive` switch in order to update and initialize the submodules, and then checkout the **dev** branch. E.g.:

    git clone https://github.com/PoshCode/PSGit.git PSGit --recursive 
    git checkout dev

The first time you set up, you need to install the LibGit2Sharp library, just run:

	.\Setup

To build, just run:

    .\Build

And then follow up by running the tests:

    .\Test

This script will download libgit2sharp (and any other dependencies we add in the future), and then create a version-number folder (e.g. "1.0") and copy all the module code to it. 

NOTE: when contributing, you should not submit anything in the numbered folders, those are release artifacts -- all edits to code should be in the /test and /src folders

#### Running Tests

To run the tests, you can just run the `Test.ps1` script (which skips `@wip` tests) or you can _run the full test suite_ by just invoking the gherkin test runner on the `/tests` subfolder:

	Invoke-Gherkin ./test

Before submitting any changes, please make sure that all tests not marked `@wip` pass, and that code coverage remains at ... well, as high as possible -- we haven't set a standard yet, although as of this writing it's at 110% ;)

### Writing Code

We are a test-driven project, so we write tests (and commit them) before we write code!


#### Writing Tests

We are using the [gherkin](https://github.com/cucumber/cucumber/wiki/Gherkin) language to define our features in terms of scenarios in an attempt to make it easy to understand what the module should do, and how it should behave. 

The first thing we do is choose or create a `.feature` file and create or modify a scenario with the steps which define our desired scenario. These feature definitions are written in a simple [Given-When-Then](https://github.com/cucumber/cucumber/wiki/Given-When-Then) syntax (you can just look at the existing .feature files for examples) which are then matched to the test steps (using simple regular expressions).

*We encourage you to submit feature descriptions with or without test steps or implementation!*

Tests which do not have an implementation yet are marked as _work in progress_ with the `@wip` tag, and you may find that the easiest way to get started actually implementing features is to just `checkout` the **dev** branch and [run the full test suite](#Running-Tests) and look at failing (or skipped) scenarios that are tagged `@wip` and implement them!

Sometimes scenarios which are marked `@wip` don't have their steps implemented. In that case, you need to write matching script-blocks in one of the `.Steps.ps1`

