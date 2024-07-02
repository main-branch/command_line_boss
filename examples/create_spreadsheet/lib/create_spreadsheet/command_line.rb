# frozen_string_literal: true

require 'command_line_boss'
require 'csv'

module CreateSpreadsheet
  # Sheet`s specified at the command line
  #
  # @!attribute title [String, nil] the title of the sheet to create or nil for the default title
  # @!attribute data [Array<Array<Object>>, nil] the data to write to the sheet or nil
  #
  # @api public
  Sheet = Struct.new(:title, :data, keyword_init: true)

  # Permissions specified at the command line
  #
  # @!attribute permission_spec [String] the unparsed permission spec as given at the command line
  # @!attribute type [String] must be one of VALID_PERM_TYPES
  # @!attribute subject [String, nil] the name of the subject the permission is given to
  #
  #   * If the type is 'user' or 'group', must be a valid email address
  #   * If type is 'domain', must be a valid domain name
  #   * If type is anyone, must be nil
  #
  # @!attribute role [String] myst be one of VALID_PERM_ROLES
  Permission = Struct.new(:permission_spec, :type, :subject, :role, keyword_init: true)

  # The list of valid permission types the user can give
  # @return [Array<String>]
  # @api private
  VALID_PERM_TYPES = %w[user group domain anyone].freeze

  # The list of valid permission roles the user can give
  # @return [Array<String>]
  # @api private
  VALID_PERM_ROLES = %w[organizer fileOrganizer writer commenter reader].freeze

  # The regular expression for parsing a permission spec
  # @return [Regexp]
  PERMISSION_SPEC_REGEXP = /
  ^
    (?<type>[^:]+)
    (?:
      :(?<subject>[^:]+)
    )?
    :(?<role>[^:]+)
    $
  /x

  # A command line interface for creating spreadsheets
  #
  # @!attribute [r] title
  #   @return [String, nil] The title of the spreadsheet to create or nil for the default title
  #
  # @!attribute [r] sheets
  #   @return [Array<Sheet>] The sheets to create in the spreadsheet
  #
  # @!attribute [r] permissions
  #   @return [Array<Permission>] The list of permissions to add to the spreadsheet
  #
  # @!attribute [r] folder_id
  #   @return [String, nil] The ID of the folder to move the spreadsheet to
  #
  # @example Create a spreadsheet named "My Spreadsheet" with a default sheet named "Sheet1"
  #   ARGV #=> ["My Spreadsheet"]
  #   options = CommandLineParser.new.call(ARGV)
  #   options.spreadsheet_title #=> "My Spreadsheet"
  #
  # @api pubic
  #
  class CommandLine < CommandLineBoss
    attr_reader :title, :sheets, :permissions, :folder_id

    private

    # Set the attribute default values
    # @return [void]
    # @api private
    def set_defaults
      @title = nil
      @sheets = []
      @permissions = []
      @folder_id = nil
    end

    # Remove the title from the remaining arguments
    # @return [void]
    # @api private
    def parse_arguments
      @title = @args.shift
    end

    # Define the --sheet option
    # @return [void]
    # @api private
    def define_sheet_option
      parser.on('--sheet=TITLE', 'Title of a sheet to create') do |title|
        if sheets.any? { |sheet| sheet.title.downcase == title.downcase }
          add_error_message("The sheet #{title} was given more than once")
        end

        sheets << Sheet.new(title:, data: nil)
      end
    end

    # Read the csv data file
    # @param data_file [String] the name of the data file
    # @return [Array<Array<Object>>, nil] the data in the file or nil if the file is not found
    # @api private
    def read_data_file(data_file)
      CSV.parse(File.read(data_file))
    rescue Errno::ENOENT
      add_error_message "Data file not found: #{data_file}"
      nil
    end

    # Define the --data option
    # @return [void]
    # @api private
    def define_data_option
      parser.on('--data=DATA_FILE', 'Data file for the last named sheet') do |data_file|
        sheets << Sheet.new(title: nil, data: nil) if sheets.empty?
        if sheets.last.data
          add_error_message 'Only one data file is allowed per sheet'
        else
          sheets.last.data = read_data_file(data_file)
        end
      end
    end

    # Define the --permission option
    # @return [void]
    # @api private
    def define_permission_option
      parser.on('--permission=PERMISSION_SPEC', 'Set permissions on the spreadsheet') do |permission_spec|
        match = permission_spec.match(PERMISSION_SPEC_REGEXP)
        unless match
          add_error_message "Invalid permission: #{permission_spec}"
          next
        end
        permissions << Permission.new(
          permission_spec:, type: match[:type], subject: match[:subject], role: match[:role]
        )
      end
    end

    # Define the --folder option
    # @return [void]
    # @api private
    def define_folder_option
      parser.on('--folder=FOLDER_ID', 'Create the spreadsheet to the given folder') do |folder_id|
        if @folder_id
          add_error_message 'Only one --folder option is allowed'
        else
          @folder_id = folder_id
        end
      end
    end

    # Validate the permission role value
    # @return [void]
    # @api private
    def validate_permission_role
      permissions.each do |p|
        add_error_message "Invalid permission role: #{p.role}" unless VALID_PERM_ROLES.include?(p.role)
      end
    end

    # Validate that no permissions of type 'anyone' has a subject
    # @return [void]
    # @api private
    def validate_permission_anyone_subject
      permissions.each do |p|
        add_error_message 'An anyone permission must not have a subject' if p.type == 'anyone' && p.subject
      end
    end

    # Validate that all permissions that are not type 'anyone' have a subject
    # @return [void]
    # @api private
    def validate_permission_other_subject
      permissions.each do |p|
        add_error_message "A #{p.type} permission must have a subject" if p.type != 'anyone' && !p.subject
      end
    end

    # Validate that all permissions have a valid type
    # @return [void]
    # @api private
    def validate_permission_type
      permissions.each do |p|
        add_error_message "Invalid permission type: #{p.type}" unless VALID_PERM_TYPES.include?(p.type)
      end
    end

    include CommandLineBoss::HelpOption

    # Banner shown at the top of the help message
    # @return [String]
    # @api private
    def banner = <<~BANNER
      Create a new Google Spreadsheet'

      Usage:

      create_spreadsheet [SPREADSHEET_TITLE] \\
        [--sheet=TITLE [--data=DATA_FILE]]... \\
        [--folder=FOLDER_ID] \\
        [--permission=PERMISSION_SPEC]...
    BANNER

    # Footer shown at the bottom of the help message
    # @return [String]
    # @api private
    def footer = <<~FOOTER
      DATA_FILE := A file containing data in CSV format
      PERMISSION_SPEC := {user:EMAIL:ROLE | group:EMAIL:ROLE | domain:DOMAIN:ROLE | anyone:ROLE}
      ROLE := {organizer | fileOrganizer | writer | commenter | reader}
    FOOTER
  end
end
