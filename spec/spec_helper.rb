require 'rubygems'
require 'bundler/setup'

require 'wordmove' # and any other gems you need
require 'wordmove/logger'
require 'active_support/core_ext'
require 'thor'

RSpec.configure do |config|
  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end
end
