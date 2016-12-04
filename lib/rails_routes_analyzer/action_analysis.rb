require_relative 'gem_manager'

require 'active_support/descendants_tracker'
require 'active_support/core_ext/class/subclasses'
require 'active_support/core_ext/string/strip'

module RailsRoutesAnalyzer
  MAX_ACTION_LENGTH = 30 # Don't align action names longer than this

  class ActionMethod < Hash
    # is_inherited - action is inherited from a parent controller
    # from_gem     - action is implemented in a gem
    # from_module  - action implementation is in a module
    %i[
      controller_name
      action_name
      route_missing
      source_location
      is_inherited
      from_gem
      from_module
      owner
    ].each do |name|
      define_method(name) { self[name] }
    end

    def initialize(opts={})
      self.update(opts)
    end

    def controller_class
      @controller_class ||= controller_name.constantize
    end

    def needs_reporting?(report_duplicates:, report_gems:, report_modules:, report_routed:, **)
      (route_missing?     || report_routed)     \
        && (!inherited?   || report_duplicates) \
        && (!from_gem?    || report_gems)       \
        && (!from_module? || report_modules)
    end

    def pretty(max_action_length: MAX_ACTION_LENGTH, metadata: false, **)
      ("%-#{max_action_length}s @ %s" % [ action_name, source_location ]).tap do |result|
        if metadata
          result << " "
          result << pretty_metadata
        end
      end
    end

    def pretty_metadata
      [
        route_missing? ? "no-route"                : nil,
        inherited?     ? "inherited:#{owner.name}" : nil,
        from_gem?      ? "gem:#{from_gem}"         : nil,
        from_module?   ? "module:#{owner.name}"    : nil,
      ].compact.join(' ')
    end

    alias_method :inherited?,     :is_inherited
    alias_method :route_missing?, :route_missing
    alias_method :from_gem?,      :from_gem
    alias_method :from_module?,   :from_module
  end

  class ActionAnalysis

    attr_reader :all_action_methods, :unused_controllers, :options

    # Options:
    #  report_duplicates - report actions which the parent controller also has
    #  report_gems       - report actions which are implemented by a gem
    #  report_modules    - report actions inherited from modules
    #  report_routed     - report all actions including those with a route
    #  full_path         - skips shortening file paths
    #  metadata          - include discovered metadata about actions
    def initialize(route_analysis: RailsRoutesAnalyzer::RouteAnalysis.new, **options)
      @options = options

      @all_action_methods = analyze_action_methods(route_analysis: route_analysis)

      @by_controller = @all_action_methods.group_by(&:controller_class)
      @unused_controllers = find_unused_controllers
    end

    def unused_actions_present?
      @all_action_methods.any? do |action|
        action.needs_reporting?(**options)
      end
    end

    def report_actions
      @controller_reporting_cache = {}

      report_actions_recursive
    end

    def actions_for(controller)
      @by_controller[controller] || []
    end

    def actions_to_report(controller)
      actions_for(controller).select do |action|
        action.needs_reporting?(**options)
      end.sort_by(&:action_name)
    end

    def report_actions_recursive(controllers = ActionController::Base.subclasses, level = 0)
      controllers.each do |controller|
        next unless controller_needs_reporting?(controller)

        puts "#{'  ' * level}#{controller.name}"

        if (actions = actions_to_report(controller)).any?
          action_level = level + 1

          if controller.subclasses.any? { |subclass| controller_needs_reporting?(subclass) }
            puts "#{'  ' * action_level}Actions:"
            action_level += 1
          end

          max_action_length = [MAX_ACTION_LENGTH, actions.map {|a| a.action_name.size }.max].min

          actions.each do |action|
            puts "#{'  '*action_level}#{action.pretty(max_action_length: max_action_length, **options)}"
          end
        end

        report_actions_recursive(controller.subclasses.sort_by(&:name), level + 1)
      end
    end

    def controller_likely_from_gem?(controller)
      actions_for(controller).all? { |action| action.from_gem? || action.from_module? || action.inherited? }
    end

    def controller_needs_reporting?(controller)
      if @controller_reporting_cache.has_key?(controller)
        return @controller_reporting_cache[controller]
      end

      @controller_reporting_cache[controller] = \
        actions_to_report(controller).any? \
        || controller.subclasses.any? { |subclass| controller_needs_reporting?(subclass) }
    end

    def find_unused_controllers
      ActionController::Base.descendants.select do |controller|
        controller_has_no_routes?(controller) \
          && !(defined?(::Rails::ApplicationController) && controller <= ::Rails::ApplicationController) \
          && (options[:report_gems] || !controller_likely_from_gem?(controller))
      end
    end

    def no_direct_routes_to?(controller)
      actions_for(controller).all?(&:route_missing?)
    end

    def controller_has_no_routes?(controller)
      no_direct_routes_to?(controller) \
        && controller.subclasses.all? { |c| controller_has_no_routes?(c) }
    end

    def analyze_action_methods(route_analysis:)
      implemented_routes = Set.new(route_analysis.implemented_routes)

      [].tap do |result|
        ActionController::Base.descendants.each do |controller|
          action_methods = controller.action_methods.to_a.map(&:to_sym)

          if (parent_controller = controller.superclass) == ActionController::Base
            parent_controller = nil
            parent_actions    = []
          else
            parent_actions    = parent_controller.action_methods.to_a.map(&:to_sym)
          end

          action_methods.each do |action_name|
            controller_name = controller.name
            source_location = get_source_location(controller, action_name)

            owner = controller.instance_method(action_name).owner

            # A very strong likelyhood is that if the method is not defined by a module
            # it comes directly from any ActionController::Base subclass.
            #
            # This knowledge helps us ignore methods which might come for example from
            # someone (possibly unwisely) including a helper directly into a controller.
            from_module = owner.class == Module

            is_inherited = parent_actions.include?(action_name) \
                             && get_source_location(parent_controller, action_name) == source_location

            route_missing = !implemented_routes.include?([controller_name, action_name])

            sanitized_location = RailsRoutesAnalyzer.sanitize_source_location(source_location, options.slice(:full_path))

            result << ActionMethod.new(
              controller_name: controller_name,
              action_name:     action_name,
              is_inherited:    is_inherited,
              route_missing:   route_missing,
              source_location: sanitized_location,
              from_gem:        GemManager.identify_gem(source_location),
              owner:           owner,
              from_module:     from_module,
            )
          end
        end
      end
    end

    def get_source_location(controller_class_or_name, action_name)
      controller = controller_class_or_name
      controller = controller.constantize if controller.is_a?(String)

      controller.instance_method(action_name).source_location.join(':')
    end

    def print_report
      unless options[:report_routed]
        if unused_controllers.present?
          puts "Controllers with no routes pointing to them:"
          unused_controllers.sort_by(&:name).each do |controller|
            puts "  #{controller.name}"
          end
          puts
        end

        unless unused_actions_present?
          puts "There are no actions without a route"
          return
        end

        puts <<-EOS.strip_heredoc
          NOTE Some gems, such as Devise, are expected to provide actions that have no matching
               routes in case a particular feature is not enabled, this is normal and expected.

               If any non-action methods are reported please consider making those non-public
               or using another solution that would make #action_methods not return those.

          Actions without a route:

        EOS
      end

      report_actions
    end

  end
end
