module FixtureHelpers
  def fixture_path_for(filename)
    File.join(__dir__, '..', 'fixtures', filename)
  end

  def fixture_root_relative_path_for(filename)
    File.join('spec', 'fixtures', filename)
  end

  def movefile_path_for(filename)
    fixture_root_relative_path_for("movefiles/#{filename}")
  end
end

RSpec.configure do |config|
  config.include FixtureHelpers
end
