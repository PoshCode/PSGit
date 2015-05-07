## Contributing

Thanks for taking an insterest in contributing to the PowerShell-enabled Git 

### Development

Development happens on the **dev** branch. Please send pull requests against that branch only.

The **master** branch should contain only features which are already releaseable (which may, or may not have features that have not already been released).

This project is organized such that:

* `/src` is the source code of the module itself
* `/test` contains the test code and .feature specifications
* `/packages` is not in the repository, but contains (nuget) packages
* `/lib` contains git submodules which point to projects that we depend on (or that are required for development).

Thus, all edits to the module code should be in the `/src` folder, and must be tested by tests in the `/test` folder.  

### Building Development Versions

To get started, you need to clone the project with the `--recursive` switch in order to update and initialize the submodules, and then checkout the **dev** branch. E.g.:

    git clone https://github.com/PoshCode/PSGit.git PSGit --recursive 
    git checkout dev

To build, just run:

    Build.ps1

This script will download libgit2sharp (and any other dependencies we add in the future), and then create a version-number folder (e.g. "1.0") and copy all the module code to it. 

NOTE: when contributing, you should not submit anything in the numbered folders, those are release artifacts -- all edits to code should be in the /test and /src folders

#### Running Tests

To run the tests, you can just run the `Build.ps1` script (which skips `@wip` tests) or you can _run the full test suite_ by just invoking the gherkin test runner on the `/tests` subfolder:

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

