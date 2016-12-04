require_relative '../route_call'

module RailsRoutesAnalyzer
  module RouteIssue

    class Base < Hash
      def self.fields(*names)
        names.each do |name|
          define_method(name) { self[name] }
          define_method("#{name}=") { |val| self[name] = val }
        end
      end

      fields :route_call

      delegate \
        :action,
        :action_names,
        :controller_class_name,
        :controller_name,
        :file_location,
        :route_creation_method,
        :present_actions,
        to: :route_call

      def initialize(opts = {})
        update(opts)
      end

      def human_readable_error(verbose: false)
        human_readable_error_message.tap do |message|
          append_verbose_message(message) if verbose
        end
      end

      def verbose_message
      end

      def suggestion(verbose: false, **kwargs)
        error_suggestion(**kwargs).tap do |message|
          append_verbose_message(message) if verbose
        end
      end

      def append_verbose_message(message)
        verbose = verbose_message
        message << "| #{verbose}" if verbose.present?
      end

      def try_to_fix_line(_line)
        raise NotImplementedError, 'should be provided by subclasses'
      end

      def format_actions(actions)
        case actions.size
        when 0
          nil
        when 1
          ":#{actions.first}"
        else
          list = actions.map { |action| ":#{action}" }.sort.join(', ')
          "[#{list}]"
        end
      end
    end

  end
end
