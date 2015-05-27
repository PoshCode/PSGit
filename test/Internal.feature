Feature: Internal Function Tests
    This will test the functionality of internal functions

    Scenario: Simple Mesage output
        Given we are NOT in a repository
        When WriteMessage is called
        Then the output should be: "TIP: test"
    
    @wip
    Scenario: Simple Mesage output
        Given we are NOT in a repository
        When WriteMessage info test is called
        Then the output should be: "INFO: test"
   
    Scenario: Simple Color convert
        Given we are NOT in a repository
        When ConvertColor is called
        Then the output should be: "Red"