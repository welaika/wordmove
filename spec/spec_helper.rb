$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'tempfile'
require 'debug'

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'wordmove'

Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }

# I don't know from where this method was imported,
# but since last updates it was lost. I looked about
# it and discovered in Rails 5 was removed becouse not
# thread safe. So I'm copying it from the new Rails 5
# implementation.
# @see https://github.com/rails/rails/commit/481e49c64f790e46f4aff3ed539ed227d2eb46cb
def silence_stream(stream)
  old_stream = stream.dup
  stream.reopen(RbConfig::CONFIG['host_os'].match?(/mswin|mingw/) ? 'NUL:' : '/dev/null')
  stream.sync = true
  yield
ensure
  stream.reopen(old_stream)
  old_stream.close
end

RSpec.configure do |config| # rubocop:disable Metrics/BlockLength
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
    mocks.verify_doubled_constant_names = true
  end

  config.example_status_persistence_file_path = './spec/examples.txt'

  config.formatter = :documentation

  config.before :each do
    allow(Wordmove::WpcliHelpers)
      .to receive(:get_option)
      .and_return('an option')

    allow(Wordmove::WpcliHelpers)
      .to receive(:get_option)
      .with('home', config_path: instance_of(String))
      .and_return('http://example.com')

    allow(Wordmove::WpcliHelpers)
      .to receive(:get_config)
      .and_return('a config')

    allow(Wordmove::WpcliHelpers)
      .to receive(:get_config)
      .with('DB_PASSWORD', config_path: instance_of(String))
      .and_return('local_database_password')

    allow(Wordmove::WpcliHelpers)
      .to receive(:get_config)
      .with('DB_HOST', config_path: instance_of(String))
      .and_return('local_database_host')

    allow(Wordmove::WpcliHelpers)
      .to receive(:get_config)
      .with('DB_NAME', config_path: instance_of(String))
      .and_return('local_database_name')
  end
end
