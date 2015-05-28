Feature: Internal Function Tests
    This will test the functionality of internal functions
    
    Scenario: Simple Message output with basic params
        Given we are NOT in a repository
        When WriteMessage info test is called
        Then the output should be: "INFO: test"
   
    Scenario: Simple Color convert
        Given we are NOT in a repository
        When ConvertColor is called
        Then the output should be: "Red"