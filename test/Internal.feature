Feature: Internal Function Tests
    This will test the functionality of internal functions
    
    Scenario: Simple Message output with basic params
        Given we are NOT in a repository
        When WriteMessage test info is called
        Then the output should be: "TEST: info"
   
    Scenario: Simple Color convert
        Given we are NOT in a repository
        When ConvertColor blue is called
        Then the output should be: "Blue"

    Scenario: Color convert in ISE
    	Given we have WPF loaded
    	When ConvertColor #00aaaaaa is called
    	Then the output should be: "White"

    Scenario: Color convert in ISE (mostly for codecov on if's)
    	Given we have WPF loaded
    	When ConvertColor #00123123 is called
    	Then the output should be: "Black"
	
	Scenario: Color Convert Transparent background
		Given we have WPF loaded
    	When ConvertColor #00FFFFFF is called
    	Then the output should be: "Black"