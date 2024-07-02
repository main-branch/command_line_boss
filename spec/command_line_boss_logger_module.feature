Feature: The CommandLineBoss::HelpOption module

  Background:
    Given a class named "CommandLine" which derives from "CommandLineBoss" with the body
      """
      include CommandLineBoss::LoggerOptions
      """
    And an instance of the "CommandLine" class is created

  Scenario: It defines the verbose option
    When the command line "%w[--verbose]" is parsed
    Then the parser should have succeeded
    And it should return a logger whose log level is 1

  Scenario: It defines the debug option
    When the command line "%w[--debug]" is parsed
    Then the parser should have succeeded
    And it should return a logger whose log level is 0

  Scenario: If neither --debug or --verbose is given
    When the command line "[]" is parsed
    Then the parser should have succeeded
    And it should return a logger whose log level is 6 and logdev is nil

  Scenario: If both --debug and --verbose is given
    When the command line "%w[--verbose --debug]" is parsed
    Then the parser should have failed
    And error_messages should contain "ERROR: Can not give both --debug and --verbose"

