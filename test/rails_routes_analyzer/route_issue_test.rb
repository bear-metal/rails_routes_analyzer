require 'test_helper'

module RailsRoutesAnalyzer
  class RouteIssueTest < Minitest::Test
    def setup_route_issues(file: 'routes_bad.rb')
      Rails.application.routes_reloader.paths.clear
      Rails.application.routes_reloader.paths << Rails.root.join(file)
      RouteAnalysis.new
    end

    def get_issue_at(location)
      file, line = location.split(':')

      analysis = setup_route_issues(file: file)
      analysis.issues.detect do |issue|
        issue.file_location == location
      end or raise("Failed to find issue at #{location}, found at: #{analysis.issues.map(&:file_location).join(', ')}")
    end

    def test_resources_action_limit_suggestion
      issue = get_issue_at 'routes_bad.rb:4'
      assert_equal "`resources' call at routes_bad.rb:4 for HomeController should use only: [:index, :show]", issue.human_readable
      assert_equal 4, issue.line_number
      assert_equal File.expand_path('../../dummy/routes_bad.rb', __FILE__), issue.full_filename
    end

    def test_custom_member_route_without_action_method
      issue = get_issue_at 'routes_bad.rb:7'
      assert_equal "`get :missing_member_action' call at routes_bad.rb:7 there is no matching action in FullItemsController", issue.human_readable
    end

    def test_custom_collection_route_without_action_method
      issue = get_issue_at 'routes_bad.rb:10'
      assert_equal "`post :missing_collection_action' call at routes_bad.rb:10 there is no matching action in FullItemsController", issue.human_readable
    end

    def test_unknown_controller
      issue = get_issue_at 'routes_bad.rb:15'
      assert_equal "`get' call at routes_bad.rb:15 there is no controller: UnknownControllerController for 'unknown_controller' (actions: [:index]) error: uninitialized constant UnknownControllerController", issue.human_readable
    end
  end
end
