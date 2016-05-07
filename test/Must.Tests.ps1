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



# This is the most basic case, in terms of the code
# And it's more thorough than the others will be in tests
Describe "Must Equal" -Tag "Acceptance" {

    It "works for the Must Equal assertion" {
        1 | Must -Equal 1
        { 2 | Must -Equal 1 } | Should Throw
        
        "Hello" | Must -Equal "Hello"
        { "Help" | Must -Equal "Hello" } | Should Throw
    }

    It "works the same for InputObject as PipelineInput for the Must Equal assertion" {
        Must -InputObject 1 -Equal 1
        { Must -InputObject 2 -Equal 1 } | Should Throw
        Must -InputObject "Hello" -Equal "Hello"
        { Must -InputObject "Help" -Equal "Hello" } | Should Throw
    }

    It "works for the Must Not Equal assertion" {
        1 | Must -Not -Equal 2
        {1 | Must -Not -Equal 1 } | Should Throw

        "Help" | Must -Not -Equal "Hello"
        { "Help" | Must -Not -Equal "Help" } | Should Throw
    }

    It "works the same for InputObject as PipelineInput for the Must Not Equal assertion" {
        Must -InputObject 1 -Not -Equal 2
        {Must -InputObject 1 -Not -Equal 1 } | Should Throw
        Must -InputObject "Help" -Not -Equal "Hello"
        { Must -InputObject "Help" -Not -Equal "Help" } | Should Throw

    }

    It "works for the Must Any Equal assertion" {
        1,2,3,4 | Must -Any -Equal 2
        {1,3,4 | Must -Any -Equal 2 } | Should Throw

        "Help","Hello" | Must -Any -Equal "Hello"
        { "Hello","Goodbye" | Must -Any -Equal "Help" } | Should Throw
    }

    It "works for the Must All Equal assertion" {
        2,2,2,2.0 | Must -All -Equal 2
        {1,1,4,1 | Must -All -Equal 1 } | Should Throw

        "hello","Hello","HELLO" | Must -All -Equal "Hello"
        { "Hello","Goodbye" | Must -All -Equal "Hello" } | Should Throw
    }

    It "works for the Must Not Any Equal assertion" {
        1,3,4 | Must -Not -Any -Equal 2
        {1,2,3,4 | Must -Not -Any -Equal 2 } | Should Throw

        "Goodbye","Help" | Must -Not -Any -Equal "Hello"
        { "Hello","Help","Goodbye" | Must -Not -Any -Equal "Help" } | Should Throw
    }

    It "works for the Must Not All Equal assertion" {
        2,2,2,1 | Must -Not -All -Equal 2
        {1,1,1 | Must -Not -All -Equal 1 } | Should Throw

        "Hello","Goodbye" | Must -Not -All -Equal "Hello"
        { "hello","Hello","HELLO" | Must -Not -All -Equal "Hello" } | Should Throw
    }

    It "works for properties" {
        $obj = New-Object PSObject -Property @{ Name = "Joel"; Id = 42 }
        $obj | Must Name -eq "Joel"
        { $obj | Must Name -Not -Equal "Joel" } | Should Throw

        $obj | Must Id -Equal 42
        $obj | Must Id -Equal "42"
        { $obj | Must Id -Not -Equal 42 } | Should Throw

        Must -Input $obj Name -eq "Joel"
        { Must -Input $obj Name -not -eq "Joel" } | Should Throw

        Must -Input $obj Id -eq 42
        { Must -Input $obj Id -not -eq 42 } | Should Throw
    }

    # bug
    It "works for properties of arrays" {
        $obj = @( 1, 2, 3 )
        Must -Input $obj Count -eq 3
    }
}

# This is the part I had the most trouble with, logic-wise
Describe "Must BeNullOrEmpty" -Tag "Acceptance" {

    It "works for the BeNullOrEmpty assertion" {
        $null | Must -BeNullOrEmpty
        "" | Must -BeNullOrEmpty
        ,@() | Must -BeNullOrEmpty


        { 2 | Must -BeNullOrEmpty } | Should Throw
        { "Help" | Must -BeNullOrEmpty } | Should Throw
        { ,@("Help") | Must -BeNullOrEmpty } | Should Throw

        # Testing an array of things which are null (the ARRAY is neither null nor empty)
        { ,@(),$Null | Must -BeNullOrEmpty } | Should Throw
    }


    It "works the same for InputObject as PipelineInput for the Must BeNullOrEmpty assertion" {
        Must -InputObject $null -BeNullOrEmpty
        Must -InputObject "" -BeNullOrEmpty
        Must -InputObject @() -BeNullOrEmpty

        { Must -InputObject 2 -BeNullOrEmpty } | Should Throw
        { Must -InputObject "Help" -BeNullOrEmpty } | Should Throw
        
        # This is a little weird, but it's correct:
        # An array with stuff in it is not null or empty, even if everything in it is nulls
        { Must -InputObject @($Null) -BeNullOrEmpty } | Should Throw
    }

    It "works for the Must Not BeNullOrEmpty assertion" {
        1 | Must -Not -BeNullOrEmpty
        "Help" | Must -Not -BeNullOrEmpty

        {@() | Must -Not -BeNullOrEmpty } | Should Throw
        {$null | Must -Not -BeNullOrEmpty } | Should Throw
        {"" | Must -Not -BeNullOrEmpty } | Should Throw

    }

    It "works the same for InputObject as PipelineInput for the Must Not BeNullOrEmpty assertion" {
        Must -InputObject 1 -Not -BeNullOrEmpty
        Must -InputObject "Help" -Not -BeNullOrEmpty
        # This is a little weird, but it's correct:
        # An array with stuff in it is not null or empty, even if everything in it is nulls
        Must -InputObject @("Stuff") -Not -BeNullOrEmpty

        { Must -InputObject @() -Not -BeNullOrEmpty } | Should Throw
        { Must -InputObject "" -Not -BeNullOrEmpty } | Should Throw
        { Must -InputObject $null -Not -BeNullOrEmpty } | Should Throw
    }

    It "works for the Must Any BeNullOrEmpty assertion" {
        1,2,$null,4 | Must -Any -BeNullOrEmpty
        {1,3,4 | Must -Any -BeNullOrEmpty } | Should Throw
        
        # This might catch people by suprise?
        1,2,@(),4 | Must -Any -BeNullOrEmpty

        "Help","Hello","" | Must -Any -BeNullOrEmpty
        { "Hello","Goodbye" | Must -Any -BeNullOrEmpty } | Should Throw
    }

    It "works for the Must All BeNullOrEmpty assertion" {
        "",$null,@() | Must -All -BeNullOrEmpty
        {"",1,$null | Must -All -BeNullOrEmpty } | Should Throw
    }

    It "works for the Must Not Any BeNullOrEmpty assertion" {
        1,3,4,@(1),"Help" | Must -Not -Any -BeNullOrEmpty
        {1,2,3,@(),4 | Must -Not -Any -BeNullOrEmpty} | Should Throw
        {1,2,3,"",4 | Must -Not -Any -BeNullOrEmpty} | Should Throw
        {1,2,3,$null,4 | Must -Not -Any -BeNullOrEmpty} | Should Throw
    }

    It "works for the Must Not All BeNullOrEmpty assertion" {
        $null, "", @(), 4 | Must -Not -All -BeNullOrEmpty
        {@(),"",$null | Must -Not -All -BeNullOrEmpty} | Should Throw
    }
}

Describe "Must Match" -Tag Acceptance {

    It "can handle the Match assertion" {
        "abcd1234" | Must -Match "d1"
    }
}

## TODO: We need more tests here to cover the other operators



## Add tests way down here when we find bugs (use "Regression" and "Acceptance" tags)


Describe "Null Value Behavior" -Tag "Regression", "Acceptance" {

    It "can test equality with Null" {
        $null | Must -Equal $Null
        {$null | Must -Not -Equal $Null} | Should Throw
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
    #     if ($PSVersionTable.PSVersion -BeNullOrEmpty "2.0") {
    #         { $(ReturnNothing) | Should Not BeNullOrEmpty } | Should Not Throw
    #     } else {
    #         { $(ReturnNothing) | Should Not BeNullOrEmpty } | Should Throw
    #     }
    # }

}
