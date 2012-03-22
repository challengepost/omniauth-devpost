require 'bundler/setup'
require 'rspec'

ENV['CHALLENGEPOST_FOUNTAINHEAD_URL'] = 'http://fountainhead.dev'

Dir[File.expand_path('../support/**/*', __FILE__)].each { |f| require f }

RSpec.configure do |config|
end