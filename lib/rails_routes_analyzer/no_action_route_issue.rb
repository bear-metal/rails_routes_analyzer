require_relative 'route_issue'

module RailsRoutesAnalyzer

  class NoActionRouteIssue < RouteIssue
    def human_readable_error_message
      missing_actions.map do |action|
        "`#{route_creation_method} :#{action}' call at #{file_location} there is no matching action in #{controller_class_name}"
      end.tap do |result|
        return nil if result.size == 0
        return result[0] if result.size == 1
      end
    end

    def error_suggestion(non_issues:, num_controllers:)
      actions = format_actions(missing_actions)
      if non_issues
        "remove case#{'s' if missing_actions.size > 1} for #{actions}"
      else
        "delete line, #{actions} matches nothing"
      end.tap do |message|
        message << " for controller #{controller_class_name}" if num_controllers > 1
      end
    end

    def try_to_fix_line(line)
      '' # Delete
    end
  end

end
