# frozen_string_literal: true

ORDINALS_TO_NUMBERS = %w[
  zeroth first second third fourth fifth sixth seventh eighth ninth tenth
  eleventh twelfth thirteenth fourteenth fifteenth sixteenth seventeenth eigthteenth nineteenth
].freeze

def ordinal_to_number(ordinal)
  ORDINALS_TO_NUMBERS.index(ordinal.downcase)
end

step 'a class named :class_name which derives from "CommandLineBoss"' do |class_name|
  @klasses ||= {}
  @klasses[class_name] = Class.new(CommandLineBoss)
end

step 'the :class_name class defines the private instance method :method_name' do |class_name, method_name|
  klass = @klasses[class_name]
  klass.define_method(method_name) {} # rubocop:disable Lint/EmptyBlock
  klass.send(:private, method_name)
end

step ':class_name defines the private instance method :method_name with the body:' do |class_name, method_name, body|
  klass = @klasses[class_name]
  klass.define_method(method_name) { eval body } # rubocop:disable Lint/Eval
  klass.send(:private, method_name)
end

step 'an instance of the :class_name class is created' do |class_name, program_name = nil|
  klass = @klasses[class_name]
  trace = TracePoint.new(:call) do |tp|
    next unless tp.self.is_a?(klass)

    next if tp.method_id == :definition_method?

    @methods_called ||= []
    @methods_called << tp.method_id
  end
  trace.enable do
    @instance = klass.new(program_name: program_name) # rubocop:disable Style/HashSyntax
  end
end

step 'an instance of :class_name is created specifying the program name :program_name' do |class_name, program_name|
  send 'an instance of the :class_name class is created', class_name, program_name
end

step 'the :attribute_name attribute should be an empty array' do |attribute_name|
  expect(@instance.send(attribute_name.to_sym)).to eq([])
end

step 'the :method_name method should have been called' do |method_name|
  expect(@methods_called).to include(method_name.to_sym)
end

step 'the :class_name class defines the instance attribute :attribute_name' do |class_name, attribute_name|
  klass = @klasses[class_name]
  klass.send(:attr_reader, attribute_name.to_sym)
end

step 'a class named :class_name which derives from "CommandLineBoss" with the body' do |class_name, body|
  @klasses ||= {}
  @klasses[class_name] = Class.new(CommandLineBoss)
  @klasses[class_name].class_eval(body)
end

step 'the command line :args is parsed' do |args|
  evaled_args = eval(args) # rubocop:disable Security/Eval

  begin
    saved_stdout = $stdout
    @captured_stdout = StringIO.new
    $stdout = @captured_stdout

    saved_stderr = $stderr
    @captured_stderr = StringIO.new
    $stderr = @captured_stderr

    @instance.parse(evaled_args)
  rescue SystemExit => e
    @system_exit_exception = e
  ensure
    $stdout = saved_stdout
    $stderr = saved_stderr
  end
end

step 'the command line :args is parsed with parse!' do |args|
  evaled_args = eval(args) # rubocop:disable Security/Eval

  begin
    saved_stdout = $stdout
    @captured_stdout = StringIO.new
    $stdout = @captured_stdout

    saved_stderr = $stderr
    @captured_stderr = StringIO.new
    $stderr = @captured_stderr

    @instance.parse!(evaled_args)
  rescue SystemExit => e
    @system_exit_exception = e
  ensure
    $stdout = saved_stdout
    $stderr = saved_stderr
  end
end

step 'the parser should have exited the program with status :exit_status' do |exit_status|
  expect(@system_exit_exception).not_to be_nil
  expect(@system_exit_exception.status).to eq(exit_status.to_i)
end

step 'the parser should not have exited the program' do
  expect(@system_exit_exception).to be_nil
end

step 'the :attribute_name attribute should eq :value' do |attribute_name, value|
  expect(@instance.send(attribute_name.to_sym)).to eq(eval(value)) # rubocop:disable Security/Eval
end

step 'parsing should have :result' do |result|
  method = :"#{result}?"
  expect(@instance.send(method)).to eq(true)
end

step 'error_messages should contain :error_message' do |error_message|
  expect(@instance.error_messages).to include(error_message)
end

step 'the parser should have output to stdout' do |output|
  expect(@captured_stdout.string).to eq(output)
end

step 'the parser should have output to stderr' do |output|
  expect(@captured_stderr.string).to eq(output)
end

step 'a :error_class error should be raised with the exit_status :exit_status' do |error_class, exit_status|
  klass = eval(error_class) # rubocop:disable Security/Eval
  expect(@system_exit_exception).to be_a(klass)
  expect(@system_exit_exception.status).to eq(exit_status.to_i)
end

step 'the parser should have succeeded' do
  expect(@instance.succeeded?).to eq(true)
end

step 'the parser should have failed' do
  expect(@instance.failed?).to eq(true)
end

step 'it should return a logger whose log level is :level' do |level|
  logger = @instance.logger
  expect(logger.level).to eq level.to_i
end

step 'it should return a logger whose log level is 6 and logdev is nil' do
  logger = @instance.logger
  expect(logger.level).to eq 6
  expect(@instance.logger.instance_variable_get(:@logdev)).to eq(nil)
end
