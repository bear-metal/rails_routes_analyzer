module RailsRoutesAnalyzer

  class RouteAnalysis
    attr_accessor :app, :verbose, :only_only, :only_except
    attr_accessor :implemented_routes, :route_log
    attr_writer :issues

    def initialize(app: Rails.application, verbose: false, only_only: false, only_except: false)
      self.app         = app
      self.verbose     = verbose
      self.only_only   = only_only
      self.only_except = only_except

      analyze!
    end

    def analyze!
      app.eager_load! # all controller classes need to be loaded

      ::ActionDispatch::Routing::Mapper::Mapping.prepend RouteInterceptor

      RouteInterceptor.route_data.clear
      RouteInterceptor.route_log.clear

      app.reload_routes!

      implemented_routes = Set.new
      issues = []

      RouteInterceptor.route_data.each do |(file_location, route_creation_method, controller_name), action_names|
        controller_class_name = "#{controller_name}_controller".camelize

        action_names = action_names.uniq.sort

        opts = {
          file_location:         file_location,
          route_creation_method: route_creation_method,
          controller_name:       controller_name,
          controller_class_name: controller_class_name,
          action_names:          action_names,
          error:                 nil,
        }

        controller = nil
        begin
          controller = Object.const_get(controller_class_name)
        rescue LoadError, RuntimeError, NameError => e
          issues << RouteIssue.new(opts.merge(type: :no_controller, error: e.message, suggestion: "delete, #{controller_class_name} not found"))
          next
        end

        if controller.nil?
          issues << RouteIssue.new(opts.merge(type: :no_controller, suggestion: "delete, #{controller_class_name} not found"))
          next
        end

        present, missing = action_names.partition {|name| controller.action_methods.include?(name.to_s) }
        extra = action_names - RESOURCE_ACTIONS

        if SINGLE_METHODS.include?(route_creation_method)
          # NOTE a single call like 'get' can add multiple actions if called in a loop
          missing.each do |action|
            issues << RouteIssue.new(opts.merge(type: :no_action, action: action, suggestion: "action :#{action} not found for #{controller_class_name}"))
          end

          present.each do |action|
            implemented_routes << [controller_class_name, action]
          end

          next
        end

        present.each {|action_name| implemented_routes << [controller_class_name, action_name] }

        if missing.empty? # Everything is perfect
          next
        end

        if present.sort == RESOURCE_ACTIONS.sort
          unless missing.empty?
            raise "shouldn't get all methods being present and missing at the same time: #{present.inspect} #{missing.inspect}"
          end
          next
        end

        suggestion = if (present.size < 4 || only_only) && !only_except
          "only: [#{present.sort.map {|x| ":#{x}" }.join(', ')}]"
        else
          "except: [#{(RESOURCE_ACTIONS - present).sort.map {|x| ":#{x}" }.join(', ')}]"
        end

        if verbose
          suggestion << " | This route currently covers unimplemented actions: [#{missing.sort.map {|x| ":#{x}" }.join(', ')}]"
        end

        issues << RouteIssue.new(opts.merge(type: :suggestion, suggestion: suggestion))
      end

      self.implemented_routes = implemented_routes
      self.route_log = RouteInterceptor.route_log.dup
      self.issues = issues
    end

    def issues
      @issues || []
    end

    def unique_issues_file_names
      issues.map { |issue| issue.full_filename }.uniq.sort
    end

    def issues_for_file_name(full_filename)
      issues.select { |issue| issue.full_filename == full_filename.to_s }
    end
  end

end
