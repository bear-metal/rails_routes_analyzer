module RailsRoutesAnalyzer

  class RouteIssue < Hash
    %i[
      action
      action_names
      missing_actions
      present_actions
      controller_class_name
      controller_name
      error
      file_location
      route_creation_method
      suggested_param
      type
      verbose_message
    ].each do |name|
      define_method(name) { self[name] }
    end

    def initialize(opts={})
      self.update(opts)
    end

    def issue?
      type != :non_issue
    end

    def resource?
      type == :resources
    end

    def full_filename
      RailsRoutesAnalyzer.get_full_filename(file_location.sub(/:[0-9]*\z/, ''))
    end

    def line_number
      file_location[/:([0-9]+)\z/, 1].to_i
    end

    def human_readable
      case self[:type]
      when :non_issue
        ''
      when :no_controller
        "`#{route_creation_method}' call at #{file_location} there is no controller: #{controller_class_name} for '#{controller_name}' (actions: #{action_names.inspect})".tap do |msg|
          msg << " error: #{error}" if error.present?
        end
      when :no_action
        missing_actions.map do |action|
          "`#{route_creation_method} :#{action}' call at #{file_location} there is no matching action in #{controller_class_name}"
        end.tap do |result|
          return nil if result.size == 0
          return result[0] if result.size == 1
        end
      when :resources
        "`#{route_creation_method}' call at #{file_location} for #{controller_class_name} should use #{suggested_param}"
      else
        raise ArgumentError, "Unknown issue_type: #{self[:type].inspect}"
      end.tap do |message|
        message << "| #{verbose_message}" if verbose_message
      end
    end

    def suggestion(non_issues:, num_controllers:)
      case self[:type]
      when :non_issue
        nil
      when :no_controller
        if non_issues
          "remove case for #{controller_class_name} as it doesn't exist"
        else
          "delete, #{controller_class_name} not found"
        end
      when :no_action
        actions = format_actions(missing_actions)
        if non_issues
          "remove case#{'s' if missing_actions.size > 1} for #{actions}"
        else
          "delete line, #{actions} matches nothing"
        end.tap do |message|
          message << " for controller #{controller_class_name}" if num_controllers > 1
        end
      when :resources
        "use #{suggested_param}".tap do |message|
          if num_controllers > 1
            message << " only for #{controller_class_name}"
          end
        end
      else
        raise ArgumentError, "Unknown issue_type: #{self[:type].inspect}"
      end.tap do |message|
        message << "| #{verbose_message}" if verbose_message
      end
    end

    def format_actions(actions)
      case actions.size
      when 0
      when 1
        ":#{actions.first}"
      else
        list = actions.map { |action| ":#{action}" }.sort.join(', ')
        "[#{list}]"
      end
    end
  end

end
