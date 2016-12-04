require 'test_helper'

module RailsRoutesAnalyzer
  class RouteLineTest < TestCase
    def get_route_line_at(location)
      analysis = setup_route_analysis(location: location)

      analysis.route_lines.detect do |line|
        line.file_location.ends_with?(location)
      end || raise("Failed to find RouteLine at #{location}, found at: #{analysis.route_lines.map(&:full_filename).uniq.join(', ')}")
    end

    def test_issues
      line = get_route_line_at 'routes_bad.rb:15'
      assert !line.present_actions?
      assert_equal 1, line.issues.size
      assert line.issues?
    end

    def test_annotate_without_iteration
      line = get_route_line_at 'routes_bad.rb:15'

      content = "  get 'unknown_controller_index', action: :index, controller: 'unknown_controller'"

      assert_equal "#{content} # SUGGESTION delete, UnknownControllerController not found",
                   line.annotate(content, try_to_fix: false, allow_deleting: false)

      assert_equal "#{content} # SUGGESTION delete, UnknownControllerController not found",
                   line.annotate(content, try_to_fix: true, allow_deleting: false)

      assert_equal "",
                   line.annotate(content, try_to_fix: true, allow_deleting: true)
    end

    def test_annotate_with_iteration
      line = get_route_line_at 'routes_bad.rb:18'

      content = '    get "unknown_index#{i}", action: :index, controller: "unknown_#{i}"'
      assert_equal "#{content} # SUGGESTION delete, Unknown0Controller not found, delete, Unknown1Controller not found",
                   line.annotate(content, try_to_fix: false, allow_deleting: false)

      assert_equal "#{content} # SUGGESTION delete, Unknown0Controller not found, delete, Unknown1Controller not found",
                   line.annotate(content, try_to_fix: true, allow_deleting: false)

      # We don't delete lines which are inside iterations even if all
      # iterations look deletable because it could leave around loops
      # with an empty body and those would be very difficult to
      # automatically remove.
      assert_equal "#{content} # SUGGESTION delete, Unknown0Controller not found, delete, Unknown1Controller not found",
                   line.annotate(content, try_to_fix: true, allow_deleting: true)
    end
  end
end
