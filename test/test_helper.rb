$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rails_routes_analyzer'

require 'minitest/color'
require 'minitest/reporters'
require 'minitest/autorun'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require 'dummy/application'

module RailsRoutesAnalyzer
  class TestCase < Minitest::Test

    def setup_route_analysis(location: nil, file: 'routes_bad.rb')
      file, _ = location.split(':') if location

      Rails.application.routes_reloader.paths.clear
      Rails.application.routes_reloader.paths << Rails.root.join(file)
      RouteAnalysis.new
    end

    def get_issue_at(location)
      analysis = setup_route_analysis(location: location)
      analysis.issues.detect do |issue|
        issue.file_location == location
      end or raise("Failed to find issue at #{location}, found at: #{analysis.issues.map(&:file_location).join(', ')}")
    end

  end
end
