Feature: Defining a command line parser

  Background:
    Given a class named "CommandLine" which derives from "CommandLineBoss"

  Scenario: It calls the set_defaults method if defined
    Given a class named "CommandLine" which derives from "CommandLineBoss" with the body
      """
      private

      def set_defaults; end
      """
    When an instance of the "CommandLine" class is created
    Then the "set_defaults" method should have been called

  Scenario: It defines the instance attributes and sets the default_values
    Given a class named "CommandLine" which derives from "CommandLineBoss" with the body
      """
      attr_reader :users, :verbose

      private

      def set_defaults
        @users = []
        @verbose = false
      end
      """
    When an instance of the "CommandLine" class is created
    Then the "users" attribute should eq "[]"
    And the "verbose" attribute should eq "false"

  Scenario: It calls the private define_*_option methods defined in the "CommandLine" class
    Given a class named "CommandLine" which derives from "CommandLineBoss" with the body
      """
      attr_reader :users, :verbose

      private

      def set_defaults
        @users = []
        @verbose = false
      end

      def define_user_option; end
      def define_verbose_option; end
      """
    When an instance of the "CommandLine" class is created
    Then the "define_user_option" method should have been called
    And the "define_verbose_option" method should have been called
