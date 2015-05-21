Set-StrictMode -Version Latest

. $PSScriptRoot\Must.Steps.ps1

Describe "Simple booleans" {
    Context "for positive assertions" {
        It "returns true if the test is true" {
            $True | Must -Equal $True
        }
    }

    Context "for negative assertions" {
        It "returns true if the test is false" {
            $False | Must -Not -Equal $True
        }
    }
}

Describe -Tag "Acceptance" "Must" {
    It "can use the Be assertion" {
        1 | Must -Equal 1
    }

    It "can use the Not Be assertion" {
        1 | Must -Not -Equal 2
    }

    It "can use the BeNullOrEmpty assertion" {
Describe "Must Match" -Tag Acceptance {

    It "can handle the Match assertion" {
        "abcd1234" | Must -Match "d1"
    }
}
        $null | Must -Equal $Null
        @()   | Must -BeNullOrEmpty
        ""    | Must -BeNullOrEmpty
    }

    It "Fails on Null values" {
        { $null | Must -Eq 4 } | Should Throw
        { @()   | Must -Eq "Something" } | Should Throw
        { ""    | Must -Not -BeNullOrEmpty } | Should Throw
    }

    It "can use the Not BeNullOrEmpty assertion" {
        @("foo") | Must -Not -BeNullOrEmpty
        "foo"    | Must -Not -BeNullOrEmpty
        "   "    | Must -Not -BeNullOrEmpty
        @(1,2,3) | Must -Not -BeNullOrEmpty
        12345    | Must -Not -BeNullOrEmpty

        $item1 = New-Object PSObject -Property @{Id=1; Name="foo"}
        $item2 = New-Object PSObject -Property @{Id=2; Name="bar"}
        @($item1, $item2) | Must -Not -BeNullOrEmpty
    }

    # It "can handle exception thrown assertions" {
    #     { foo } | Should Throw
    # }

    # It "can handle exception should not be thrown assertions" {
    #     { $foo = 1 } | Should Not Throw
    # }

    # It "can handle Exist assertion" {
    #     $TestDrive | Should Exist
    # }

    # It "can test for file contents" {
    #     Setup -File "test.foo" "expected text"
    #     "$TestDrive\test.foo" | Should Contain "expected text"
    # }

    # It "ensures all assertion functions provide failure messages" {
    #     $assertionFunctions = @("PesterBe", "PesterThrow", "PesterBeNullOrEmpty", "PesterExist", "PesterMatch", "PesterContain")
    #     $assertionFunctions | % {
    #         "function:$($_)FailureMessage" | Should Exist
    #         "function:Not$($_)FailureMessage" | Should Exist
    #     }
    # }

    # # TODO understand the purpose of this test, perhaps some better wording
    # It "can process functions with empty output as input" {
    #     function ReturnNothing {}

    #     # TODO figure out why this is the case
    #     if ($PSVersionTable.PSVersion -eq "2.0") {
    #         { $(ReturnNothing) | Should Not BeNullOrEmpty } | Should Not Throw
    #     } else {
    #         { $(ReturnNothing) | Should Not BeNullOrEmpty } | Should Throw
    #     }
    # }

}
