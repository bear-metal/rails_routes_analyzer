require_relative 'route_call'

module RailsRoutesAnalyzer

  class RouteIssue < RouteCall
    fields \
      :error,
      :missing_actions

    def issue?
      true
    end

    def human_readable_error(verbose: false)
      human_readable_error_message.tap do |message|
        append_verbose_message(message) if verbose
      end
    end

    def get_verbose_message
    end

    def suggestion(verbose: false, **kwargs)
      error_suggestion(**kwargs).tap do |message|
        append_verbose_message(message) if verbose
      end
    end

    def append_verbose_message(message)
      if (verbose_message = get_verbose_message).present?
        message << "| #{verbose_message}"
      end
    end

    def try_to_fix_line(line)
      raise NotImplementedError, 'should be provided by subclasses'
    end

    def format_actions(actions)
      case actions.size
      when 0
      when 1
        ":#{actions.first}"
      else
        list = actions.map { |action| ":#{action}" }.sort.join(', ')
        "[#{list}]"
      end
    end
  end

end
