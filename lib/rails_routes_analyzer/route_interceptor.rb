module RailsRoutesAnalyzer

  # Plugs into ActionDispatch::Routing::Mapper::Mapping to help get detailed information
  # on which route was generated, exactly where and if there is a matching controller action
  module RouteInterceptor
    ROUTE_METHOD_REGEX = /action_dispatch\/routing\/mapper.rb:[0-9]+:in `(#{Regexp.union(*::RailsRoutesAnalyzer::ROUTE_METHODS)})'\z/

    def self.route_data
      @route_data ||= {}
    end

    def self.route_log
      @route_log ||= []
    end

    # Finds the most interesting Rails.root file from the backtrace that called a method in mapper.rb
    def get_routes_rb_location
      bt = caller
      base = 0
      while true
        index = bt[base..-1].index {|l| l =~ ROUTE_METHOD_REGEX }
        return "" if index.nil?

        next_line = bt[base + index + 1]

        if next_line =~ /action_dispatch\/routing\/mapper.rb/
          base += index + 1
          next
        else
          file_location = next_line[/:?\A#{Rails.root}\/(.*:[0-9]+)/, 1] || next_line

          bt[base + index] =~ ROUTE_METHOD_REGEX
          route_creation_method = $1

          return [file_location, route_creation_method]
        end
      end
    end

    def check_controller_and_action(path_params, controller_name, action)
      super.tap do
        if controller_name && action
          location = get_routes_rb_location + [controller_name]

          if location[0].nil?
            puts "Failed to find call location for: #{controller_name}/#{action}"
          else
            (RouteInterceptor.route_data[location] ||= []) << action.to_sym
            RouteInterceptor.route_log << [controller_name, action.to_sym]
          end
        end
      end
    end
  end

end
