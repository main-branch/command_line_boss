# CommandLineBoss

[![Gem Version](https://badge.fury.io/rb/command_line_boss.svg)](https://badge.fury.io/rb/command_line_boss)
[![Documentation](https://img.shields.io/badge/Documentation-Latest-green)](https://rubydoc.info/gems/command_line_boss/)
[![Change Log](https://img.shields.io/badge/CHANGELOG-Latest-green)](https://rubydoc.info/gems/command_line_boss/file/CHANGELOG.md)
[![Build Status](https://github.com/main-branch/command_line_boss/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/main-branch/command_line_boss/actions/workflows/continuous_integration.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/513b4d8d95a5e3a77ec6/maintainability)](https://codeclimate.com/github/main-branch/command_line_boss/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/513b4d8d95a5e3a77ec6/test_coverage)](https://codeclimate.com/github/main-branch/command_line_boss/test_coverage)

Command Line Boss is built on top of OptionsParser with the aim to make more
complicated uses of OptionsParser easier to manage.

* [Installation](#installation)
* [Usage](#usage)
* [Example](#example)
  * [Step 1: Define requirements](#step-1-define-requirements)
  * [Step 2: Design the command line](#step-2-design-the-command-line)
  * [Step 3: Implement readers and default values for the returned attributes](#step-3-implement-readers-and-default-values-for-the-returned-attributes)
  * [Step 3: Write tests](#step-3-write-tests)
  * [Step 4: Set default attribute values](#step-4-set-default-attribute-values)
  * [Step 5: Define options](#step-5-define-options)
  * [Step 6: Define validations](#step-6-define-validations)
  * [Step 7: Parse remaining command line arguments](#step-7-parse-remaining-command-line-arguments)
  * [Step 8: Make the --help output look good](#step-8-make-the---help-output-look-good)
* [Development](#development)
* [Contributing](#contributing)
* [License](#license)
* [Code of Conduct](#code-of-conduct)

## Installation

Install the gem and add to the application's Gemfile by executing:

```shell
bundle add command_line_boss
```

If bundler is not being used to manage dependencies, install the gem by executing:

```shell
gem install command_line_boss
```

## Usage

Ideally, with a command line parser class, you want a class that you can simply pass
in ARGV to the parser and get the values parsed from the command line using getter
methods.

## Example

This example shows step-by-step how to write a class that implements parsing the
command line for creating a Google Docs Spreadsheet.

### Step 1: Define requirements

Write a class that implements parsing the command line that meets the following
requirements:

* Optionally specify the **title** of the spreadsheet. If not specified, use the
  default title for new spreadsheets (usually "Untitled Spreadsheet")
* Optionally specify a list of **sheets** to create and give an optional CSV data
  file to preload into the sheet. If no sheets are specified, one blank sheet is
  created with the default title (usually "Sheet 1"). If a data file is not specified
  for a given sheet, that sheet should be left blank.
* Optionally specify a list of **permissions** to add to the spreadsheet. The user
  must be able to specify the type of the permission (user, group, domain, or
  anyone), the subject of the permission (depending on the type either an email
  address, domain name or nothing), and the role being granted (organizer
  fileOrganizer writer commenter reader).
* Optionally specify the Google Drive **folder** to create the spreadsheet in. If not
  given, the spreadsheet will be created in the root drive directory of the user
  whose credentials are being used to make the request.

Once the command line is parsed, return this information in the following attributes:

* **title**: the optional title of the spreadsheet
* **sheets**: an array of sheets each having a **title** and **data** read from the given CSV
* **permissions**: an array of permissions each having a **type**, **subject**, and **role**
* **folder_id**: the id of the Google Drive folder

### Step 2: Design the command line

Design your command line following the
[Google developer documentation style guide for command line syntax](https://developers.google.com/style/code-syntax).

Document what the `--help` option SHOULD output in the following sections:

```text
BANNER
USAGE
OPTIONS
FOOTER
```

For this example, it would looks something like this:

```text
Create a new Google Spreadsheet

Usage:

create_spreadsheet [SPREADSHEET_TITLE] \
  [--sheet-title=TITLE [--sheet-data=DATA_FILE]]... \
  [--folder=FOLDER_ID }] \
  [--permission=PERMISSION_SPEC]...

Options:
        --sheet-title=TITLE          Title of a sheet to create
        --sheet-data=DATA_FILE       Data file for the last sheet
        --folder=FOLDER_ID           Create the spreadsheet in the given Google Drive folder
        --permission=PERMISSION_SPEC Set permissions on the spreadsheet

DATA_FILE := A file containing data in CSV format
PERMISSION_SPEC := {user:EMAIL:ROLE | group:EMAIL:ROLE | domain:DOMAIN:ROLE | anyone:ROLE}
ROLE := {organizer | fileOrganizer | writer | commenter | reader}
```

### Step 3: Implement readers and default values for the returned attributes

```ruby
class CreateSpreadsheetCli < CommandLineBoss
  attr_reader :title, :sheets, :folder, :permissions

  private

  def set_defaults
      @title = nil
      @sheets = []
      @permissions = []
      @folder_id = nil
  end
end
```

In this case, it would be advantageous to create a few supporting classes and
constants to return sheets and permissions.

```ruby
# Sheets specified at the command line
#
# @!attribute title [String, nil] the title of the sheet to create or nil for the default title
# @!attribute data [Array<Array<Object>>, nil] the data to write to the sheet or nil
#
# @api public
Sheet = Struct.new(:title, :data)

# Permissions specified at the command line
#
# @!attribute type [String] must be one of VALID_PERM_TYPES
# @!attribute subject [String, nil] the name of the subject the permission is given to
#
#   * If the type is 'user' or 'group', must be a valid email address
#   * If type is 'domain', must be a valid domain name
#   * If type is anyone, must be nil
#
# @!attribute role [String] myst be one of VALID_PERM_ROLES
Permission = Struct.new(:type, :subject, :role)

VALID_PERM_TYPES = %w[user group domain anyone].freeze
VALID_PERM_ROLES = %w[organizer fileOrganizer writer commenter reader].freeze
```

### Step 3: Write tests

### Step 4: Set default attribute values

```ruby
```

### Step 5: Define options

Define private methods whose name is define_*_option.

Methods MUST be private or they won't be called.

Add any errors to the `error_messages` array.

```ruby
private

def define_sheet_title_option
  parser.on('--sheet-title=TITLE', 'Title of a sheet to create') do |title|
    sheets << Sheet.new(title:, data: nil)
  end
end

def define_sheet_data_option
  parser.on('--sheet-data=DATA_FILE', 'Data file for the last sheet') do |data_file|
    sheets << Sheet.new(title: nil, data: nil) if sheets.empty?
    if sheets.last.data
      error_messages << 'Only one --sheet-data option is allowed per --sheet-title'
    else
      sheets.last.data = CSV.read(data_file)
    end
  end
end

def define_folder_option
  parser.on('--folder=FOLDER_ID', 'Create the spreadsheet to the given folder') do |folder_id|
    if @folder_id
      error_messages << 'Only one --folder option is allowed'
    else
      @folder_id = folder_id
    end
  end
end

PERMISSION_SPEC_REGEXP = /
  ^
  (?<type>[^:]+)
  (?:
    :(?<subject>[^:]+)
  )?
  :(?<role>[^:]+)
  $
/x

def define_permission_option
  parser.on('--permission=PERMISSION_SPEC', 'Set permissions on the spreadsheet') do |permission_spec|
    match = permission_spec.match(PERMISSION_SPEC_REGEXP)
    unless match
      error_messages << "Invalid permission spec: #{permission_spec}"
      next
    end
    permissions << Permission.new(
      permission_spec:, type: match[:type], subject: match[:subject], role: match[:role]
    )
  end
end
```

### Step 6: Define validations

Define private methods whose name is validate_*.

Methods MUST be private or they won't be called.

Add any errors to the `error_messages` array.

```ruby
def validate_permission_types
  permissions.each do |permission|
    unless VALID_PERMISSION_TYPES.include?(permission.type)
      error_messages << "Invalid permission type: #{permission.type}"
    end
  end
end

def validate_permission_roles
  permissions.each do |permission|
    unless VALID_PERMISSION_ROLES.include?(permission.role)
      error_messages << "Invalid permission role: #{permission.role}"
    end
  end
end

def validate_permission_subjects
  permissions.each do |permission|
    if permission.type == 'anyone' && permission.subject
      error_messages << "Permission subject for type 'anyone' should be blank in #{permission.permission_spec}"
    end
    if permission.type != 'anyone' && !permission.subject
      error_messages << "Permission subject missing in #{permission.permission_spec}"
    end
  end
end
```

### Step 7: Parse remaining command line arguments

```ruby
def parse_arguments
  @spreadsheet_title = args.shift
end
```

### Step 8: Make the --help output look good

```ruby
def banner = <<~TEXT
  Create a new Google Spreadsheet
TEXT

# Usage text for the command line help
# @api private
def usage = <<~TEXT
  Usage:

  create_spreadsheet SPREADSHEET_TITLE \
    [--sheet-title=TITLE [--sheet-data=DATA_FILE]]... \
    [--folder=FOLDER_ID }] \
    [--permission=PERMISSION_SPEC]...
TEXT

# Footer text for the command line help
# @api private
def footer = <<~TEXT
  PERMISSION_SPEC := {user:EMAIL:ROLE | group:EMAIL:ROLE | domain:DOMAIN:ROLE | anyone:ROLE}
  ROLE := {organizer | fileOrganizer | writer | commenter | reader}
  DATA_FILE := A file containing data in CSV format
TEXT
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/command_line_boss. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/command_line_boss/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the CommandLineBoss project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/command_line_boss/blob/main/CODE_OF_CONDUCT.md).
