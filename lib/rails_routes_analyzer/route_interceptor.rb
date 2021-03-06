require 'rails/version'

module RailsRoutesAnalyzer

  # Plugs into ActionDispatch::Routing::Mapper::Mapping to help get detailed information
  # on which route was generated, exactly where and if there is a matching controller action
  module RouteInterceptor
    ROUTE_METHOD_REGEX = %r{action_dispatch/routing/mapper.rb:[0-9]+:in `(#{Regexp.union(*::RailsRoutesAnalyzer::ROUTE_METHODS)})'\z}

    def self.route_data
      {}.tap do |result|
        route_log.each do |(location, _controller_name, action, _request_methods)|
          (result[location] ||= []) << action
        end
      end
    end

    def self.route_log
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

    if Rails::VERSION::MAJOR == 3
      def initialize(*args)
        super.tap do
          record_route(@options[:controller], @options[:action], conditions[:request_method])
        end
      end
    elsif Rails::VERSION::MAJOR == 4
      def initialize(*args)
        super.tap do
          record_route(@defaults[:controller], @defaults[:action], conditions[:request_method])
        end
      end
    else # Rails 5+
      def initialize(*args)
        super.tap do
          record_route(@defaults[:controller], @defaults[:action], request_method.map(&:verb))
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

        RouteInterceptor.route_log << record
      end
    end

  end

end
