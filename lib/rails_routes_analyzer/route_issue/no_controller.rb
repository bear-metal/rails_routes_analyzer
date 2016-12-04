require_relative 'base'

module RailsRoutesAnalyzer
  module RouteIssue

    class NoController < Base

      fields :error

      def human_readable_error_message
        "`#{route_creation_method}' call at #{file_location} there is no controller: #{controller_class_name} for '#{controller_name}' (actions: #{action_names.inspect})".tap do |msg|
          msg << " error: #{error}" if error.present?
        end
      end

      def error_suggestion(has_present_actions:, **)
        if has_present_actions
          "remove case for #{controller_class_name} as it doesn't exist"
        else
          "delete, #{controller_class_name} not found"
        end
      end

      def try_to_fix_line(_line)
        '' # Delete
      end
    end

  end
end
