# frozen_string_literal: true

class CommandLineBoss
  # Add the --help option
  module HelpOption
    private

    # Define the command line options
    #
    # @return [void]
    #
    # @api private
    #
    def define_options
      add_banner
      add_header
      super
      add_footer
    end

    # Define the --help option
    #
    # @return [void]
    #
    # @api private
    #
    def define_help_option
      parser.on('-h', '--help', 'Show this message') do
        puts parser.help
        exit
      end
    end

    # Adds the banner to the parser output
    # @return [void]
    # @api private
    #
    def add_banner
      return unless banner

      parser.banner = banner
    end

    # Derived classes should override this method to provide a banner
    # @return [String, nil]
    # @api private
    #
    def banner = nil

    # Adds the header to the parser output
    # @return [void]
    # @api private
    #
    def add_header
      return unless header

      parser.separator header
    end

    # Derived classes should override this method to provide a header
    # @return [String, nil]
    # @api private
    #
    def header = nil

    # Adds the footer to the parser output
    # @return [void]
    # @api private
    #
    def add_footer
      return unless footer

      parser.separator footer
    end

    # Derived classes should override this method to provide a footer
    # @return [String, nil]
    # @api private
    #
    def footer = nil
  end
end
