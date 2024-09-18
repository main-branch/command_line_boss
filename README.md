# The `command_line_boss` gem

[![Gem Version](https://badge.fury.io/rb/command_line_boss.svg)](https://badge.fury.io/rb/command_line_boss)
[![Documentation](https://img.shields.io/badge/Documentation-Latest-green)](https://rubydoc.info/gems/command_line_boss/)
[![Change Log](https://img.shields.io/badge/CHANGELOG-Latest-green)](https://rubydoc.info/gems/command_line_boss/file/CHANGELOG.md)
[![Build Status](https://github.com/main-branch/command_line_boss/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/main-branch/command_line_boss/actions/workflows/continuous_integration.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/513b4d8d95a5e3a77ec6/maintainability)](https://codeclimate.com/github/main-branch/command_line_boss/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/513b4d8d95a5e3a77ec6/test_coverage)](https://codeclimate.com/github/main-branch/command_line_boss/test_coverage)
[![Slack](https://img.shields.io/badge/slack-main--branch/command__line__boss-yellow.svg?logo=slack)](https://main-branch.slack.com/archives/C07MQC0LNKF)

`command_line_boss` makes it easy to build, test, and maintain complex command line
interfaces. It is built on top of Ruby's `OptionParser` class and works best for
traditional options-based command-line interfaces that you would build with
`OptionParser`.

To use `command_line_boss` you are expected to already know how to define options
with `OptionParser`.

For defining command-line interfaces with multiple commands and subcommands (aka a
git-like interface), we recommend using a gem like [thor](http://whatisthor.com).
Other good alternatives also exist.

* [Installation](#installation)
* [Usage](#usage)
  * [Getting started](#getting-started)
  * [Design your command line](#design-your-command-line)
  * [Start your command line parser class](#start-your-command-line-parser-class)
  * [Define options](#define-options)
  * [Define additional validations](#define-additional-validations)
  * [Process any remaining non-option arguments](#process-any-remaining-non-option-arguments)
  * [Optional: define help output](#optional-define-help-output)
  * [Use the parser](#use-the-parser)
  * [Run the command line](#run-the-command-line)
* [Development](#development)
* [Contributing](#contributing)
* [License](#license)
* [Code of Conduct](#code-of-conduct)

## Installation

To install this gem, add to the following line to your application's gemspec OR
Gemfile:

gemspec:

```ruby
  spec.add_development_dependency "command_line_boss", '~> 0.1'
```

Gemfile:

```ruby
gem "command_line_boss", "~> 0.1", groups: [:development, :test]
```

and then run `bundle install`.

If bundler is not being used to manage dependencies, install the gem by executing:

```shell
gem install command_line_boss
```

## Usage

More detailed examples are given in the `examples` directory.

* `examples/readme_example` - a super-simple example of using this gem. The
  remainder of this section is a walkthrough of this example was constructed.
* `examples/create_spreadsheet` - a more complicated example complete with
  tests.

This section provides a step-by-step guide to building a super simple command line
using this gem. A parser this simple would probably be easier to implement with
`OptionParser` directly without this gem. This example is meant to show how you
can get started.

This gem really starts to shine as your command-line interface grows beyond
something this simple.

### Getting started

The end result of this guide can be found in this project in the file
`examples/readme_example/create-spreadsheet`.

Find a suitable directory to create your code in. For this example, all the code
will live in ONE script file that you create and set its executable permission bit
via `chmod`.

Make sure you have the `command_line_boss` gem installed.

### Design your command line

Design the command line following the [Google developer documentation style guide for
command line syntax](https://developers.google.com/style/code-syntax).

Here is what a simple example might look like that creates a spreadsheet with named
sheets:

```Text
Usage:
create_spreadsheet SPREADSHEET_NAME --sheet=SHEET_NAME [--sheet=SHEET_NAME ...]
```

### Start your command line parser class

The first step will be to create your own command line parsing class. This class
must inherit from `CommandLineBoss`.

Add the attributess representing the items you want to capture from the command
line. Set default values for these attributes in a method called `set_defaults`.

```Ruby
#!/usr/bin/env ruby

require 'command_line_boss'

class CreateSpreadsheetCli < CommandLineBoss
  attr_reader :spreadsheet_name, :sheet_names

  private

  def set_defaults
      @spreadsheet_name = nil
      @sheet_names = []
  end
end
```

### Define options

Define private methods whose names follow the pattern `define_*_option`. Methods
MUST be private or they won't be called.

Report any errors by calling `add_error_message` with the text of the error
message.

The return value of these methods is ignored.

Continuing the example, add the following code to the `CreateSpreadsheetCli` class:

```Ruby
class CreateSpreadsheetCli < CommandLineBoss
  # ...

  private

  def define_sheet_option
    parser.on('--sheet=SHEET_NAME', 'Name of a sheet to create') do |name|
      add_error_message('Sheet names must be unique!') if sheet_names.include?(name)
      sheet_names << name
    end
  end
end
```

### Define additional validations

Define private methods whose names follow the pattern `validate_*`. Methods MUST
be private or they won't be called.

Report any errors by calling `add_error_message` with the text of the error
message.

The return value of these methods is ignored.

Continuing the example, add the following code to the `CreateSpreadsheetCli` class:

```Ruby
class CreateSpreadsheetCli < CommandLineBoss
  # ...

  private

  def validate_spreadsheet_name_given
    add_error_message('A spreadsheet name is required') if spreadsheet_name.nil?
  end

  def validate_at_least_one_sheet_name_given
    add_error_message('At least one sheet name is required') if sheet_names.empty?
  end
end
```

### Process any remaining non-option arguments

Implement `parse_arguments` to deal the remaining non-option arguments from the
command line. Within this method, the `args` method returns the remaining
non-option arguments.

For example, in the command line `create-spreadsheet "Yearly Sales" --sheet Summary`,
`args` would return an array `['Yearly Sales']`.

Remove any values from `args` that will be used. By default, if `args` is not
empty after `parse_arguments` returns, an error will result.

Report any errors by calling `add_error_message` with the text of the error
message.

The return value of this method is ignored.

Continuing the example, add the following code to the `CreateSpreadsheetCli` class:

```Ruby
class CreateSpreadsheetCli < CommandLineBoss
  # ...

  private

  def parse_arguments
    @spreadsheet_name = args.shift
  end
end
```

### Optional: define help output

Include the `CommandLineBoss::HelpOption` module add a help option (`-h` and
`--help`) and structure the help output.

Help output is divided into sections that is output as follows:

```text
BANNER
HEADER
OPTIONS
FOOTER
```

The OPTIONS section is generated by `OptionsParser`.

You may provide the content for the other sections by implementing any or all of the
methods: `banner`, `header`, and `footer`. These methods are expected to return a
string with the content.

If you do not provide content for the `banner` section, it is generated by
`OptionsParser`. The default banner looks something like this:

```text
Usage: create-spreadsheet [options]
```

If you do not provide content for the `header` or `footer` sections, they are
omitted from the help output.

Continuing the example, add the following code to the `CreateSpreadsheetCli` class:

```Ruby
class CreateSpreadsheetCli < CommandLineBoss
  include CommandLineBoss::HelpOption

  # ...

  private

  include CommandLineBoss::HelpOption

  def banner = <<~BANNER
    Create a spreadsheet

    Usage:
      create_spreadsheet SPREADSHEET_NAME --sheet=SHEET_NAME [--sheet=SHEET_NAME ...]

  BANNER
end
```

The `CreateSpreadsheetCli` class is complete!

### Use the parser

Now that the command line parser is fully defined, you just need to use it,
report errors, and (if successful) do something with the parsed values.

Place the following code at the end of your script file, after the
`CreateSpreadsheetCli` class:

```Ruby
# Parse the command line arguments

options = CreateSpreadsheetCli.new.parse(ARGV)

# Report errors

if options.failed?
  warn options.error_messages.join("\n")
  exit 1
end

# Do something with the result
# In this case just output the command line values

require 'pp'

puts \
  "Creating spreadsheet #{options.spreadsheet_name.pretty_inspect.chomp} " \
  "with sheets #{options.sheet_names.map(&:pretty_inspect).map(&:chomp).join(', ')}"
```

### Run the command line

Should you have a problem running your script, you can compare your script against
the expected result which can be found in this project in the file
`examples/readme_example/create-spreadsheet`.

Test your script by running it from the command line. Here are some examples:

Show help output:

```shell
$ ./create-spreadsheet --help
Create a spreadsheetasdf

Usage:
  create_spreadsheet SPREADSHEET_NAME --sheet=SHEET_NAME [--sheet=SHEET_NAME ...]

Options:
        --sheet=SHEET_NAME           Name of a sheet to create
    -h, --help                       Show this message

$
```

A happy-path example:

```shell
$ ./create-spreadsheet 'Yearly Sales' --sheet=Summary --sheet=Details
Creating spreadsheet "Yearly Sales" with sheets "Summary", "Details"
$
```

An example with errors:

```shell
$ ./create-spreadsheet
ERROR: A spreadsheet name is required
ERROR: At least one sheet name is required
$
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake
spec` to run the tests. You can also run `bin/console` for an interactive prompt that
will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/main_branch/command_line_boss. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to adhere to
the [code of
conduct](https://github.com/main_branch/command_line_boss/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the CommandLineBoss project's codebases, issue trackers, chat
rooms and mailing lists is expected to follow the [code of
conduct](https://github.com/[USERNAME]/command_line_boss/blob/main/CODE_OF_CONDUCT.md).
