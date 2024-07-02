Feature: The CommandLineBoss::HelpOption module

  Background:
    Given a class named "CommandLine" which derives from "CommandLineBoss" with the body
      """
      include CommandLineBoss::HelpOption

      def banner = "BANNER"
      def header = "HEADER"
      def footer = "FOOTER"
      """
    And an instance of the "CommandLine" class is created

  Scenario: It displays help
    When the command line "%w[--help]" is parsed
    Then the parser should have succeeded
    And the parser should have output to stdout
      """
      BANNER
      HEADER
      Options:
          -h, --help                       Show this message

      FOOTER

      """
    And a SystemExit error should be raised with the exit_status 0

  Scenario: Sections that are not defined are not displayed in the help output
    Given a class named "CommandLine" which derives from "CommandLineBoss" with the body
      """
      include CommandLineBoss::HelpOption

      def banner = "BANNER"
      # def header = "HEADER"
      # def footer = "FOOTER"
      """
    And an instance of the "CommandLine" class is created
    When the command line "%w[--help]" is parsed
    Then the parser should have succeeded
    And the parser should have output to stdout
      """
      BANNER
      Options:
          -h, --help                       Show this message


      """

  Scenario: It just output default usage and options when no sections are defined
    Given a class named "CommandLine" which derives from "CommandLineBoss" with the body
      """
      include CommandLineBoss::HelpOption
      """
    And an instance of the "CommandLine" class is created
    When the command line "%w[--help]" is parsed
    Then the parser should have succeeded
    And the parser should have output to stdout
      """
      Usage: rspec [options]
      Options:
          -h, --help                       Show this message


      """

  Scenario: Overriding the program name
    Given a class named "CommandLine" which derives from "CommandLineBoss" with the body
      """
      include CommandLineBoss::HelpOption
      """
    And an instance of "CommandLine" is created specifying the program name "fizzbuzz"
    When the command line "%w[--help]" is parsed
    Then the parser should have succeeded
    And the parser should have output to stdout
      """
      Usage: fizzbuzz [options]
      Options:
          -h, --help                       Show this message


      """

  Scenario: Using the overriden program name in the usage message
    Given a class named "CommandLine" which derives from "CommandLineBoss" with the body
      """
      include CommandLineBoss::HelpOption

      def usage = "Usage: #{program_name} [options]"
      """
    And an instance of "CommandLine" is created specifying the program name "fizzbuzz"
    When the command line "%w[--help]" is parsed
    Then the parser should have succeeded
    And the parser should have output to stdout
      """
      Usage: fizzbuzz [options]
      Options:
          -h, --help                       Show this message


      """
