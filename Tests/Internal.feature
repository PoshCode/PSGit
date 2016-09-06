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

    Scenario: no WPF support
    	When ConvertColor #00aaaaaa is called
    	Then it will Throw a Terminating Error

    Scenario: Color convert in ISE
    	Given we have WPF loaded
    	When ConvertColor #ffffff is called
    	Then the output should be: "White"

    Scenario: Color convert in ISE (mostly for codecov on if's)
    	Given we have WPF loaded
    	When ConvertColor #00123123 is called
    	Then the output should be: "Black"
	
	Scenario: Color Convert Transparent background
		Given we have WPF loaded
    	When ConvertColor #00FFFFFF is called
    	Then the output should be: "Black"

    Scenario: Color Convert Default param test
        When ConvertColor is called with Default set to red
        Then the output should be: "Red"

    Scenario: Color Convertwith no param
        When ConvertColor is called
        Then the output should be: "Yellow"