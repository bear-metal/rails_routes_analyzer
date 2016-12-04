module RailsRoutesAnalyzer

  # Represents both positive and negative information collected
  # about a specific call that generated Rails routes.
  #
  # If called in a loop each iteration generates a new record.
  class RouteCall < Hash
    def self.fields(*names)
      names.each { |name| define_method(name) { self[name] } }
    end

    fields \
      :action,
      :action_names,
      :controller_class_name,
      :controller_name,
      :file_location,
      :route_creation_method,
      :present_actions

    def initialize(**kwargs)
      update(kwargs)
    end

    def issues
      self[:issues] ||= []
    end

    def add_issue(issue)
      issue.route_call = self
      issues << issue
    end

    def issue?
      issues.any?
    end

    def present_actions?
      present_actions.present?
    end

    def full_filename
      @full_filename ||= RailsRoutesAnalyzer.get_full_filename(file_location.sub(/:[0-9]*\z/, ''))
    end

    def line_number
      @line_number ||= file_location[/:([0-9]+)\z/, 1].to_i
    end

    def suggestion(**kwargs)
      issues.map { |issue| issue.suggestion(**kwargs) }.join('; ')
    end

    def human_readable_error(**kwargs)
      issues.map { |issue| issue.human_readable_error(**kwargs) }.join('; ')
    end

    def try_to_fix_line(line)
      return if issues.size != 1

      issues[0].try_to_fix_line(line)
    end
  end

end
