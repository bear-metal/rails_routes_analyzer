require_relative 'route_line'
require_relative 'route_call'
require_relative 'route_issue'
require_relative 'route_interceptor'

module RailsRoutesAnalyzer

  RESOURCE_ACTIONS = [:index, :create, :new, :show, :update, :destroy, :edit].freeze

  class RouteAnalysis
    attr_accessor :app, :verbose, :only_only, :only_except
    attr_accessor :route_lines, :route_calls

    def initialize(app: Rails.application, verbose: false, only_only: false, only_except: false)
      self.app         = app
      self.verbose     = verbose
      self.only_only   = only_only
      self.only_except = only_except

      analyze!
    end

    def clear_data
      @route_interceptor = nil
      self.route_lines = []
      self.route_calls = []
    end

    def route_interceptor
      @route_interceptor ||= RouteInterceptor.new(app: app)
    end

    delegate :route_log, to: :route_interceptor

    def analyze!
      clear_data

      route_interceptor.route_data.each do |(file_location, route_creation_method, controller_name), action_names|
        analyse_route_call(
          file_location:         file_location,
          route_creation_method: route_creation_method,
          controller_name:       controller_name,
          action_names:          action_names.uniq.sort,
        )
      end

      generate_route_lines
    end

    def generate_route_lines
      calls_per_line = route_calls.group_by do |record|
        [record.full_filename, record.line_number]
      end

      calls_per_line.each do |(full_filename, line_number), records|
        route_lines << RouteLine.new(full_filename: full_filename,
                                     line_number:   line_number,
                                     records:       records)
      end
    end

    def analyse_route_call(**kwargs)
      controller_class_name = "#{kwargs[:controller_name]}_controller".camelize

      opts = kwargs.merge(controller_class_name: controller_class_name)

      route_call = RouteCall.new(opts)
      route_calls << route_call

      controller = nil
      begin
        controller = Object.const_get(controller_class_name)
      rescue LoadError, RuntimeError, NameError => e
        route_call.add_issue RouteIssue::NoController.new(error: e.message)
        return
      end

      if controller.nil?
        route_call.add_issue RouteIssue::NoController.new(error: "#{controller_class_name} is nil")
        return
      end

      analyze_action_availability(controller, route_call, **opts)
    end

    # Checks which if any actions referred to by the route don't exist.
    def analyze_action_availability(controller, route_call, **opts)
      present, missing = opts[:action_names].partition { |name| controller.action_methods.include?(name.to_s) }

      route_call[:present_actions] = present if present.any?

      if SINGLE_METHODS.include?(opts[:route_creation_method])
        # NOTE a single call like 'get' can add multiple actions if called in a loop
        if missing.present?
          route_call.add_issue RouteIssue::NoAction.new(missing_actions: missing)
        end
        return
      end

      return if missing.empty? # Everything is perfect, all routes match an action

      if present.sort == RESOURCE_ACTIONS.sort
        # Should happen only if RESOURCE_ACTIONS doesn't match which actions rails supports
        raise "shouldn't get all methods being present and yet some missing at the same time: #{present.inspect} #{missing.inspect}"
      end

      suggested_param = resource_route_suggested_param(present)

      route_call.add_issue RouteIssue::Resources.new(suggested_param: suggested_param)
    end

    def resource_route_suggested_param(present)
      if (present.size < 4 || only_only) && !only_except
        "only: [#{present.sort.map { |x| ":#{x}" }.join(', ')}]"
      else
        "except: [#{(RESOURCE_ACTIONS - present).sort.map { |x| ":#{x}" }.join(', ')}]"
      end
    end

    def issues
      route_calls.select(&:issue?)
    end

    def non_issues
      route_calls.reject(&:issue?)
    end

    def all_unique_issues_file_names
      issues.map(&:full_filename).uniq.sort
    end

    def route_calls_for_file_name(full_filename)
      route_calls.select { |record| record.full_filename == full_filename.to_s }
    end

    def implemented_routes
      Set.new.tap do |implemented_routes|
        route_calls.each do |route_call|
          (route_call.present_actions || []).each do |action|
            implemented_routes << [route_call.controller_class_name, action]
          end
        end
      end
    end

    def route_lines_for_file(full_filename)
      route_lines.select { |line| line.full_filename == full_filename.to_s }
    end

    def print_report
      if issues.empty?
        puts "No route issues found"
        return
      end

      issues.each do |issue|
        puts issue.human_readable_error(verbose: verbose)
      end
    end
  end

end
