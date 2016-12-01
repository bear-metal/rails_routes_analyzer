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

    def initialize(opts={})
      self.update(opts)
    end

    def issue?
      false
    end

    def full_filename
      @full_filename ||= RailsRoutesAnalyzer.get_full_filename(file_location.sub(/:[0-9]*\z/, ''))
    end

    def line_number
      @line_number ||= file_location[/:([0-9]+)\z/, 1].to_i
    end
  end

end
