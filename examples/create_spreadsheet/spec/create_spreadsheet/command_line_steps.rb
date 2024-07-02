# frozen_string_literal: true

step 'the command line :command_line' do |command_line|
  @args = command_line.split
end

# step 'the command line is parsed' do
#   @options = CreateSpreadsheetCli.new.parse(@args)
# end

step 'the command line is parsed' do
  stdout = StringIO.new
  stderr = StringIO.new
  original_stdout = $stdout
  original_stderr = $stderr

  begin
    $stdout = stdout
    $stderr = stderr
    @options = CreateSpreadsheet::CommandLine.new.parse(@args)
  rescue StandardError => e
    @error = e
    @options = e.parser
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  @stdout = stdout.string
  @stderr = stderr.string
end

step 'the parser should have succeeded' do
  expect(@options.error_messages).to eq([])
  expect(@error).to be_nil
  expect(@stdout).to be_empty
  expect(@stderr).to be_empty
end

step 'the parser should have failed' do
  expect(@options.error_messages).not_to be_empty
  expect(@error).to be_nil
  expect(@stdout).to be_empty
  expect(@stderr).to be_empty
end

step 'the parser should have failed with the error :message' do |message|
  expect(@options.error_messages).not_to be_empty
  expect(@error).to be_nil
  expect(@stdout).to be_empty
  expect(@stderr).to be_empty
  expect(@options.error_messages).to include(message)
end

step 'the :attribute attribute should be nil' do |attribute|
  expect(@options.send(attribute.to_sym)).to be_nil
end

step 'the :attribute attribute should be empty' do |attribute|
  expect(@options.send(attribute.to_sym)).to be_empty
end

step 'the :attribute attribute should be ":value"' do |attribute, value|
  expect(@options.send(attribute.to_sym)).to eq(value)
end

step 'the sheets attribute should contain the following Sheets:' do |hash_as_string|
  # rubocop:disable Security/Eval
  expected_sheets = eval(hash_as_string).map { |s| CreateSpreadsheet::Sheet.new(s) }
  # rubocop:enable Security/Eval
  expect(@options.sheets).to match_array(expected_sheets)
end

RSpec.configure do |config|
  config.before(type: :feature) do
    allow(File).to receive(:read).and_call_original
  end
end

step 'a file :path containing:' do |path, content|
  allow(File).to receive(:read).with(path).and_return(content)
end

step 'the file :path does not exist' do |path|
  allow(File).to receive(:read).with(path).and_raise(Errno::ENOENT, "No such file or directory @ rb_sysopen - #{path}")
end

step 'the permissions attribute should contain the following Permissions:' do |hash_as_string|
  # rubocop:disable Security/Eval
  expected_permissions = eval(hash_as_string).map { |p| CreateSpreadsheet::Permission.new(p) }
  # rubocop:enable Security/Eval
  expect(@options.permissions).to match_array(expected_permissions)
end
