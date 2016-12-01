require 'test_helper'

module RailsRoutesAnalyzer
  class NoActionRouteIssueTest < TestCase
    def test_custom_member_route_without_action_method
      issue = get_issue_at 'routes_bad.rb:7'
      assert_equal "`get :missing_member_action' call at routes_bad.rb:7 there is no matching action in FullItemsController", issue.human_readable_error
    end

    def test_custom_collection_route_without_action_method
      issue = get_issue_at 'routes_bad.rb:10'
      assert_equal "`post :missing_collection_action' call at routes_bad.rb:10 there is no matching action in FullItemsController", issue.human_readable_error
    end
  end
end
