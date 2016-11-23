module RailsRoutesAnalyzer

  class RouteIssue < Hash
    %i[
      action
      action_names
      controller_class_name
      controller_name
      error
      file_location
      route_creation_method
      suggestion
      type
    ].each do |name|
      define_method(name) { self[name] }
    end

    def initialize(opts={})
      self.update(opts)
    end

    def full_filename
      RailsRoutesAnalyzer.get_full_filename(file_location.sub(/:[0-9]*\z/, ''))
    end

    def line_number
      file_location[/:([0-9]+)\z/, 1].to_i
    end

    def human_readable
      case self[:type]
      when :no_controller
        "`#{route_creation_method}' call at #{file_location} there is no controller: #{controller_class_name} for '#{controller_name}' (actions: #{action_names.inspect})".tap do |msg|
          msg << " error: #{error}" if error.present?
        end
      when :no_action
        "`#{route_creation_method} :#{action}' call at #{file_location} there is no matching action in #{controller_class_name}"
      when :suggestion
        "`#{route_creation_method}' call at #{file_location} for #{controller_class_name} should use #{suggestion}"
      else
        raise ArgumentError, "Unknown issue_type: #{self[:type].inspect}"
      end
    end
  end

end
