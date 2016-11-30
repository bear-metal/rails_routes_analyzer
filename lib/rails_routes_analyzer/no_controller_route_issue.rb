require_relative 'route_issue'

module RailsRoutesAnalyzer

  class NoControllerRouteIssue < RouteIssue
    def human_readable_error_message
      "`#{route_creation_method}' call at #{file_location} there is no controller: #{controller_class_name} for '#{controller_name}' (actions: #{action_names.inspect})".tap do |msg|
        msg << " error: #{error}" if error.present?
      end
    end

    def error_suggestion(non_issues:, num_controllers:)
      if non_issues
        "remove case for #{controller_class_name} as it doesn't exist"
      else
        "delete, #{controller_class_name} not found"
      end
    end

    def try_to_fix_line(line)
      '' # Delete
    end
  end

end
