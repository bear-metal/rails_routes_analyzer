require_relative 'route_line'
require_relative 'route_record'
require_relative 'no_action_route_issue'
require_relative 'no_controller_route_issue'
require_relative 'resources_route_issue'

module RailsRoutesAnalyzer

  class RouteAnalysis
    attr_accessor :app, :verbose, :only_only, :only_except
    attr_accessor :route_log, :route_lines, :route_records

    def initialize(app: Rails.application, verbose: false, only_only: false, only_except: false)
      self.app         = app
      self.verbose     = verbose
      self.only_only   = only_only
      self.only_except = only_except

      analyze!
    end

    def clear_data
      self.route_lines   = []
      self.route_records = []
      self.route_log     = []
    end

    def prepare_for_analysis
      app.eager_load! # all controller classes need to be loaded

      ::ActionDispatch::Routing::Mapper::Mapping.prepend RouteInterceptor

      RouteInterceptor.route_log.clear

      app.reload_routes!
    end

    def analyze!
      clear_data
      prepare_for_analysis

      RouteInterceptor.route_data.each do |(file_location, route_creation_method, controller_name), action_names|
        analyse_route_call(
          file_location:         file_location,
          route_creation_method: route_creation_method,
          controller_name:       controller_name,
          action_names:          action_names.uniq.sort,
        )
      end

      route_log.concat RouteInterceptor.route_log
      generate_route_lines
    end

    def generate_route_lines
      route_records.group_by do |record|
        [ record.full_filename, record.line_number ]
      end.each do |(full_filename, line_number), records|
        route_lines << RouteLine.new(full_filename: full_filename,
                                     line_number:   line_number,
                                     records:       records)
      end
    end

    def analyse_route_call(**kwargs)
      controller_class_name = "#{kwargs[:controller_name]}_controller".camelize

      opts = kwargs.merge(controller_class_name: controller_class_name)

      controller = nil
      begin
        controller = Object.const_get(controller_class_name)
      rescue LoadError, RuntimeError, NameError => e
        route_records << NoControllerRouteIssue.new(opts.merge(error: e.message))
        return
      end

      if controller.nil?
        route_records << NoControllerRouteIssue.new(opts)
        return
      end

      analyze_action_availability(controller, **opts.merge(controller_class_name: controller.name))
    end

    # Checks which if any actions referred to by the route don't exist.
    def analyze_action_availability(controller, **opts)
      present, missing = opts[:action_names].partition {|name| controller.action_methods.include?(name.to_s) }

      if present.any?
        route_records << RouteRecord.new(opts.merge(present_actions: present))
      end

      if SINGLE_METHODS.include?(opts[:route_creation_method])
        # NOTE a single call like 'get' can add multiple actions if called in a loop
        if missing.present?
          route_records << NoActionRouteIssue.new(opts.merge(missing_actions: missing))
        end
        return
      end

      return if missing.empty? # Everything is perfect, all routes match an action

      if present.sort == RESOURCE_ACTIONS.sort
        # Should happen only if RESOURCE_ACTIONS doesn't match which actions rails supports
        raise "shouldn't get all methods being present and yet some missing at the same time: #{present.inspect} #{missing.inspect}"
      end

      suggested_param = resource_route_suggested_param(present)

      if verbose
        verbose_message = "This route currently covers unimplemented actions: [#{missing.sort.map {|x| ":#{x}" }.join(', ')}]"
      end

      route_records << ResourcesRouteIssue.new(opts.merge(suggested_param: suggested_param, verbose_message: verbose_message))
    end

    def resource_route_suggested_param(present)
      suggested_param = if (present.size < 4 || only_only) && !only_except
        "only: [#{present.sort.map {|x| ":#{x}" }.join(', ')}]"
      else
        "except: [#{(RESOURCE_ACTIONS - present).sort.map {|x| ":#{x}" }.join(', ')}]"
      end
    end

    def issues
      route_records.select(&:issue?)
    end

    def non_issues
      route_records.reject(&:issue?)
    end

    def all_unique_issues_file_names
      issues.map(&:full_filename).uniq.sort
    end

    def route_records_for_file_name(full_filename)
      route_records.select { |record| record.full_filename == full_filename.to_s }
    end

    def implemented_routes
      Set.new.tap do |implemented_routes|
        non_issues.each do |non_issue|
          non_issue.present_actions.each do |action|
            implemented_routes << [non_issue.controller_class_name, action]
          end
        end
      end
    end

    def route_lines_for_file(full_filename)
      route_lines.select { |line| line.full_filename == full_filename.to_s }
    end
  end

end
