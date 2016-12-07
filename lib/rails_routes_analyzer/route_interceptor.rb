require 'rails/version'

module RailsRoutesAnalyzer

  # Plugs into ActionDispatch::Routing::Mapper::Mapping to help get detailed information
  # on which route was generated, exactly where and if there is a matching controller action
  class RouteInterceptor
    ROUTE_METHOD_REGEX = %r{action_dispatch/routing/mapper.rb:[0-9]+:in `(#{Regexp.union(*::RailsRoutesAnalyzer::ROUTE_METHODS)})'\z}

    def initialize(app: Rails.application)
      app.eager_load! # all controller classes need to be loaded

      trace = TracePoint.trace(:return) do |tp|
        if tp.defined_class <= ::ActionDispatch::Routing::Mapper::Mapping && tp.method_id == :initialize
          options =
            case Rails::VERSION::MAJOR
            when 3
              tp.self.instance_variable_get(:@options)
            else
              tp.self.instance_variable_get(:@defaults)
            end

          request_methods =
            case Rails::VERSION::MAJOR
            when 3, 4
              tp.self.send(:conditions)[:request_method]
            else
              tp.self.send(:request_method).map(&:verb)
            end

          record_route(options[:controller], options[:action], request_methods)
        end
      end

      app.reload_routes!
    ensure
      trace.disable
    end

    def route_data
      @route_data ||= {}.tap do |result|
        route_log.each do |(location, _controller_name, action, _request_methods)|
          (result[location] ||= []) << action
        end
      end
    end

    def route_log
      @route_log ||= []
    end

    # Finds the most interesting Rails.root file from the backtrace that called a method in mapper.rb
    def routes_rb_location
      bt = caller
      base = 0
      loop do
        index = bt[base..-1].index { |l| l =~ ROUTE_METHOD_REGEX }
        return "" if index.nil?

        next_line = bt[base + index + 1]

        if next_line =~ %r{action_dispatch/routing/mapper.rb}
          base += index + 1
          next
        else
          file_location = next_line[%r{:?\A#{Rails.root}\/(.*:[0-9]+)}, 1] || next_line

          route_creation_method = bt[base + index][ROUTE_METHOD_REGEX, 1]

          return [file_location, route_creation_method]
        end
      end
    end

    def record_route(controller_name, action, request_methods)
      return unless controller_name && action

      location = routes_rb_location + [controller_name]

      if location[0].nil?
        puts "Failed to find call location for: #{controller_name}/#{action}"
      else
        record = [location, controller_name, action.to_sym, request_methods]

        route_log << record
      end
    end

  end

end
