# frozen_string_literal: true

class CommandLineBoss
  # Add --debug and --verbose options and a logger method
  module LoggerOptions
    # true if the --debug option was given
    #
    # @return [Boolean]
    #
    # @api private
    #
    attr_reader :debug

    # true if the --verbose option was given
    #
    # @return [Boolean]
    #
    # @api private
    #
    attr_reader :verbose

    # The logger to use to report progress
    #
    # Messages are logged at info and debug levels. The logger returned is one of
    # the following:
    #
    # * A logger that logs to the console at the :info level if verbose mode is enabled
    # * A logger that logs to the console at the :debug level if debug mode is enabled
    # * Otherwise a null logger that does not log anything
    #
    # @example
    #   options.logger #=> #<Logger:0x00007f9e3b8b3e08>
    #
    # @return [Logger]
    #
    def logger
      @logger ||=
        if verbose
          verbose_logger
        elsif debug
          debug_logger
        else
          Logger.new(nil, level: Logger::UNKNOWN + 1)
        end
    end

    private

    # Define the --verbose option
    #
    # @return [void]
    #
    # @api private
    #
    def define_verbose_option
      parser.on('-v', '--verbose', 'Enable verbose mode (default is off)') do |verbose|
        @verbose = verbose
      end
    end

    # Define the --debug option
    #
    # @return [void]
    #
    # @api private
    #
    def define_debug_option
      parser.on('-D', '--debug', 'Enable debug mode default is off') do |debug|
        @debug = debug
      end
    end

    # Ensure that the --debug and --verbose options are not both given
    #
    # @return [void]
    #
    # @api private
    #
    def validate_debug_verbose_option
      add_error_message('Can not give both --debug and --verbose') if debug && verbose
    end

    # A Logger that logs to the console at the :debug level with a simple formatter
    #
    # @return [Logger]
    #
    # @api private
    #
    def debug_logger
      Logger.new($stdout, level: 'debug', formatter: ->(_severity, _datetime, _progname, msg) { "#{msg}\n" })
    end

    # A Logger that logs to the console at the :info level with a simple formatter
    #
    # @return [Logger]
    #
    # @api private
    #
    def verbose_logger
      Logger.new($stdout, level: 'info', formatter: ->(_severity, _datetime, _progname, msg) { "#{msg}\n" })
    end
  end
end
