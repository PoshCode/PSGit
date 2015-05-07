## Contributing

Thanks for taking an insterest in contributing to the PowerShell-eabled Git 


### Development

Development happens on the **dev** branch. Please send pull requests against that
branch only.

The Master branch represents code which is already releaseable (which may, or may 
not have features that have not already been released).


This project is organized such that:

* /src is the source code of the module itself
* /test contains the test code and .feature specifications
* /packages is not in the repository, but contains (nuget) packages
* /lib contains git submodules which point to projects that we either depend on, 
  or that are required for development

Thus, all edits to the module code should be in the `/src` folder, and must be tested by tests in the `/test` folder.  

##### Testing

We are a test-driven project, so we write tests (and commit them) before we write code! 

Tests which do not have an implementation yet are marked as work in progress with the `@wip` tag, and you may find that the fastest way to get started helping us is to `checkout` the **dev** branch and [run the full test suite](#Running-Tests) and look at failing (or skipped) tests that are tagged `@wip` and implement them!

### Building Development Versions

To get started, you need to clone the project with the `--recursive` switch in order to update and initialize the submodules, and then checkout the **dev** branch. E.g.:

    git clone https://github.com/PoshCode/PSGit.git PSGit --recursive 
    git checkout dev

To build, just run:

    Build.ps1

This script will download libgit2sharp (and any other dependencies we add in the future), and then create a version-number folder (e.g. "1.0") and copy all the module code to it. 

NOTE: when contributing, you should not submit anything in the numbered folders, those are release artifacts -- all edits to code should be in the /test and /src folders

#### Running Tests

To run the tests, you can just run the `Build.ps1` script (which skips `@wip` tests) or you can run them all by just invoking the gherkin test runner on the `/tests` subfolder:

	Invoke-Gherkin ./test

Before submitting any changes, please make sure that all tests not marked `@wip` pass, and that code coverage remains at ... well, as high as possible -- we haven't set a standard yet, although as of this writing it's at 110% ;)