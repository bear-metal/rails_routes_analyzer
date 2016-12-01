require 'test_helper'

module RailsRoutesAnalyzer
  module RouteIssue

    class NoControllerTest < TestCase

      def test_unknown_controller_human_readable_error
        issue = get_issue_at 'routes_bad.rb:15'
        assert_equal "`get' call at routes_bad.rb:15 there is no controller: UnknownControllerController for 'unknown_controller' (actions: [:index]) error: uninitialized constant UnknownControllerController", issue.human_readable_error
      end

      def test_unknown_controller_suggestion_without_iteration
        issue = get_issue_at 'routes_bad.rb:15'
        assert_equal "delete, UnknownControllerController not found",
          issue.suggestion(non_issues: false, num_controllers: 1)

        assert_equal "remove case for UnknownControllerController as it doesn't exist",
          issue.suggestion(non_issues: true, num_controllers: 1)
      end

      def test_unknown_controller_suggestion_with_iteration
        issue = get_issue_at 'routes_bad.rb:18'
        assert_equal "delete, Unknown0Controller not found",
          issue.suggestion(non_issues: false, num_controllers: 2)

        assert_equal "remove case for Unknown0Controller as it doesn't exist",
          issue.suggestion(non_issues: true, num_controllers: 2)
      end
    end

  end
end
