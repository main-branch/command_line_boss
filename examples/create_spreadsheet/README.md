# Example: create-spreadsheet

Ideally, with a command line parser class, you want a class that you can simply pass
in ARGV to the parser and get the values parsed from the command line using getter
methods.

This example shows step-by-step how to write a class that implements parsing the
command line for creating a Google Docs Spreadsheet.

* [Step 1: Define requirements](#step-1-define-requirements)
* [Step 2: Design the command line](#step-2-design-the-command-line)
* [Step 3: Implement accessors and set default values for result attributes](#step-3-implement-accessors-and-set-default-values-for-result-attributes)
* [Step 4: Write tests](#step-4-write-tests)
* [Step 5: Define options](#step-5-define-options)
* [Step 6: Define validations](#step-6-define-validations)
* [Step 7: Parse remaining command line arguments](#step-7-parse-remaining-command-line-arguments)
* [Step 8: Make the --help output look good](#step-8-make-the---help-output-look-good)

## Step 1: Define requirements

For this example, write a class that implements parsing the command line that meets
the following requirements:

* Optionally specify the **title** of the spreadsheet. If not specified, use the
  default title assigned by Google for new spreadsheets (usually "Untitled
  Spreadsheet")
* Optionally specify a list of **sheets** to create and give an optional CSV data
  file to preload into each sheet. If no sheets are specified, one blank sheet is
  created by Google with the default title (usually "Sheet 1"). If a data file is not
  specified for a given sheet, that sheet should be left blank.
* Optionally specify a list of **permissions** to add to the spreadsheet. The user
  must be able to specify the type of the permission (user, group, domain, or
  anyone), the subject of the permission (depending on the type either an email
  address, domain name or nothing), and the role being granted (organizer,
  fileOrganizer, writer, commenter, or reader).
* Optionally specify the Google Drive **folder** to create the spreadsheet in. If not
  given, the spreadsheet will be created in the root drive directory of the user
  whose credentials are being used to make the request.

Once the command line is parsed, return this information in the following attributes:

* **title**: the optional title of the spreadsheet
* **sheets**: an array of sheets each having attributes **title** and **data** (read from the given CSV)
* **permissions**: an array of permissions each having attributes **type**, **subject**, and **role**
* **folder_id**: the id of the Google Drive folder in which to create the spreadsheet

## Step 2: Design the command line

Design the command line following the
[Google developer documentation style guide for command line syntax](https://developers.google.com/style/code-syntax).

Document what the `--help` option SHOULD output in the following sections:

```text
BANNER
HEADER
OPTIONS
FOOTER
```

For this example, here is what the --help output should be:

```text
Create a new Google Spreadsheet

Usage:

create_spreadsheet [SPREADSHEET_TITLE] \
  [--sheet=TITLE [--data=DATA_FILE]]... \
  [--folder=FOLDER_ID] \
  [--permission=PERMISSION_SPEC]...

Options:
        --sheet=TITLE                Title of a sheet to create
        --data=DATA_FILE             Data file for the last sheet
        --folder=FOLDER_ID           Create the spreadsheet in the given Google Drive folder
        --permission=PERMISSION_SPEC Set permissions on the spreadsheet

DATA_FILE := A file containing data in CSV format
PERMISSION_SPEC := {user:EMAIL:ROLE | group:EMAIL:ROLE | domain:DOMAIN:ROLE | anyone:ROLE}
ROLE := {organizer | fileOrganizer | writer | commenter | reader}
```

## Step 3: Implement accessors and set default values for result attributes

In the requirements, there were 4 public attributes defined for this command line
parser: title, sheets, permissions, and folder_id. Use the private `set_defaults`
method to set the default values for each attribute.

```ruby
# Parse the command line for creating a Google Spreadsheet
#
# @example
#   options = CreateSpreadsheetCLI.new.call(ARGV)
#
# @!attribute title [String, nil] the title to give the new spreadsheet or nil for the default
# @!attribute sheets [Array<Sheet>] the sheets to create including title and data for each
# @!attribute permissions [Array<Permission>] the permissions to add to the spreadsheet
# @!attribute folder_id [String] the id of the Google Drive folder in which to create the spreadsheet
#
# @api public
#
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
constants to return sheets and permissions. Add the following code to the
CreateSpreadsheetCli class.

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

## Step 4: Write tests

Write tests in your favorite testing framework that assert various permutations of
command line arguments result either in:

* The expected attrbiute values, or
* The expected exception was raised

Tests for this example can be found in spec/create_spreadsheet.feature`
Tests for this interface might include:

* Nothing is given on the command line
* A spreadsheet title is given
* A sheet is defined with a title
* A sheet is defined with a title and data
* Multiple sheets are defined both with data
* Multiple sheets are defined only one with data
* A user permission is given
* A group permission is given
* A domain permission is given
* An anyone permission is given
* Multiple permissions are given
* A folder is given
* A sheet given without a name
* A permission is given without a permission spec
* A invalid permission is given
* The permission spec has an invalid type
* A permission spec has an invalid role
* A subject is given for an anyone permission
* A subject is not given for a user permission
* Data is given without a path
* Data is given with an non-existant path
* The folder option is given twice
* A same sheet name is given twice
* Data is given twice for the same sheet

## Step 5: Define options

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

## Step 6: Define validations

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

## Step 7: Parse remaining command line arguments

```ruby
def parse_arguments
  @spreadsheet_title = args.shift
end
```

## Step 8: Make the --help output look good

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
