require_relative 'base'

module RailsRoutesAnalyzer
  module RouteIssue

    class NoAction < Base

      fields :missing_actions

      def human_readable_error_message
        messages = missing_actions.map do |action|
          "`#{route_creation_method} :#{action}' call at #{file_location} there is no matching action in #{controller_class_name}"
        end

        return if messages.empty?

        messages.size == 1 ? messages[0] : messages
      end

      def error_suggestion(has_present_actions:, num_controllers:)
        actions = format_actions(missing_actions)
        if has_present_actions
          "remove case#{'s' if missing_actions.size > 1} for #{actions}"
        else
          "delete line, #{actions} matches nothing"
        end.tap do |message|
          message << " for controller #{controller_class_name}" if num_controllers > 1
        end
      end

      def try_to_fix_line(_line)
        '' # Delete
      end
    end

  end
end
