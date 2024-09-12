Feature: Parsing the command line

  Background:
    Given a class named "CommandLine" which derives from "CommandLineBoss" with the body
      """
      attr_reader :users, :verbose

      # For testing
      attr_reader :set_defaults_called, :define_user_option_called, :define_verbose_option_called

      private

      def set_defaults
        @users = []
        @verbose = false
        @set_defaults_called = true
      end

      def define_user_option
        @parser.on("-u", "--user USER", "Add a user") do |user|
          if user == 'root'
            add_error_message("User 'root' is not allowed")
            next
          end

          @users << user
        end
        @define_user_option_called = true
      end

      def define_verbose_option
        @parser.on("-v", "--[no-]verbose", "Run verbosely") do |verbose|
          @verbose = verbose
        end
        @define_verbose_option_called = true
      end
      """
    And an instance of the "CommandLine" class is created

  Scenario: It calls all the private define_*_option methods defined in the "CommandLine" class
    When the command line "[]" is parsed
    Then the "define_user_option" method should have been called
    And the "define_verbose_option" method should have been called

  Scenario: It returns default values for attributes when there are no command line args
    When the command line "[]" is parsed
    Then the "users" attribute should eq "[]"
    And the "verbose" attribute should eq "false"

  Scenario: When given a single user it returns that user in the "users" attribute
    When the command line "%w[--user James]" is parsed
    Then parsing should have succeeded
    And the "users" attribute should eq '["James"]'

  Scenario: When given multiple users it returns all users in the users attribute
    When the command line "%w[--user=James --user=John]" is parsed
    Then parsing should have succeeded
    And the "users" attribute should eq '["James", "John"]'

  Scenario: When the verbose option is given it sets verbose to true
    When the command line "%w[--verbose]" is parsed
    Then parsing should have succeeded
    And the "verbose" attribute should eq "true"

  Scenario: When the --no-verbose option is given it sets verbose to false
    When the command line "%w[--verbose --no-verbose]" is parsed
    Then parsing should have succeeded
    And the "verbose" attribute should eq "false"

  Scenario: When the --user option is given with 'root' parsing should fail and return an error message
    When the command line "%w[--user root]" is parsed
    Then parsing should have failed
    And error_messages should contain "ERROR: User 'root' is not allowed"

  Scenario: When an unexpected option is given parsing should fail and return an error message
    When the command line "%w[--unexpected]" is parsed
    Then parsing should have failed
    And error_messages should contain "ERROR: invalid option: --unexpected"

  Scenario: When an unexpected argument is given parsing should fail and return an error message
    When the command line "%w[unexpected]" is parsed
    Then parsing should have failed

  Scenario: When asked to output errors and exit and there is an error
    When the command line "%w[unexpected]" is parsed with parse!
    Then the parser should have failed
    Then the parser should have output to stderr
      """
      ERROR: Unexpected arguments: unexpected

      """
    And the parser should have exited the program with status 1

  Scenario: When asked to output errors and exit and there is NOT an error
    When the command line "%w[--user example]" is parsed with parse!
    Then the parser should have succeeded
    And the parser should not have exited the program
