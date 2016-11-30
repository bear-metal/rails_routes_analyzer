module RailsRoutesAnalyzer

  class RouteAnalysis
    attr_accessor :app, :verbose, :only_only, :only_except
    attr_accessor :route_log
    attr_writer :all_issues

    def initialize(app: Rails.application, verbose: false, only_only: false, only_except: false)
      self.app         = app
      self.verbose     = verbose
      self.only_only   = only_only
      self.only_except = only_except

      analyze!
    end

    def prepare_for_analysis
      app.eager_load! # all controller classes need to be loaded

      ::ActionDispatch::Routing::Mapper::Mapping.prepend RouteInterceptor

      RouteInterceptor.route_log.clear

      app.reload_routes!
    end

    def analyze!
      prepare_for_analysis

      all_issues = []

      RouteInterceptor.route_data.each do |(file_location, route_creation_method, controller_name), action_names|
        result = analyse_route_call(
          file_location:         file_location,
          route_creation_method: route_creation_method,
          controller_name:       controller_name,
          action_names:          action_names.uniq.sort,
        )
        all_issues.concat Array.wrap(result)
      end

      self.route_log = RouteInterceptor.route_log.dup
      self.all_issues = all_issues
    end

    def analyse_route_call(**kwargs)
      controller_class_name = "#{kwargs[:controller_name]}_controller".camelize

      opts = kwargs.merge(controller_class_name: controller_class_name)

      controller = nil
      begin
        controller = Object.const_get(controller_class_name)
      rescue LoadError, RuntimeError, NameError => e
        return NoControllerRouteIssue.new(opts.merge(error: e.message))
      end

      if controller.nil?
        return NoControllerRouteIssue.new(opts)
      end

      return analyze_action_availability(controller, **opts.merge(controller_class_name: controller.name))
    end

    # Checks which if any actions referred to by the route don't exist.
    def analyze_action_availability(controller, **opts)
      [].tap do |result|
        present, missing = opts[:action_names].partition {|name| controller.action_methods.include?(name.to_s) }

        if present.any?
          result << RouteRecord.new(opts.merge(present_actions: present))
        end

        if SINGLE_METHODS.include?(opts[:route_creation_method])
          # NOTE a single call like 'get' can add multiple actions if called in a loop
          if missing.present?
            result << NoActionRouteIssue.new(opts.merge(missing_actions: missing))
          end

          return result
        end

        return result if missing.empty? # Everything is perfect

        if present.sort == RESOURCE_ACTIONS.sort
          unless missing.empty?
            raise "shouldn't get all methods being present and missing at the same time: #{present.inspect} #{missing.inspect}"
          end
          return result
        end

        suggested_param = resource_route_suggested_param(present)

        if verbose
          verbose_message = "This route currently covers unimplemented actions: [#{missing.sort.map {|x| ":#{x}" }.join(', ')}]"
        end

        result << ResourcesRouteIssue.new(opts.merge(suggested_param: suggested_param, verbose_message: verbose_message))
      end
    end

    def resource_route_suggested_param(present)
      suggested_param = if (present.size < 4 || only_only) && !only_except
        "only: [#{present.sort.map {|x| ":#{x}" }.join(', ')}]"
      else
        "except: [#{(RESOURCE_ACTIONS - present).sort.map {|x| ":#{x}" }.join(', ')}]"
      end
    end

    def all_issues
      @all_issues || []
    end

    def issues
      all_issues.select(&:issue?)
    end

    def non_issues
      all_issues.reject(&:issue?)
    end

    def all_unique_issues_file_names
      all_issues.map { |issue| issue.full_filename }.uniq.sort
    end

    def unique_issues_file_names
      issues.map { |issue| issue.full_filename }.uniq.sort
    end

    def all_issues_for_file_name(full_filename)
      all_issues.select { |issue| issue.full_filename == full_filename.to_s }
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
  end

end
