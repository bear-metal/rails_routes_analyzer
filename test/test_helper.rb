$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rails_routes_analyzer'

require 'minitest/color'
require 'minitest/reporters'
require 'minitest/autorun'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require 'dummy/application'
