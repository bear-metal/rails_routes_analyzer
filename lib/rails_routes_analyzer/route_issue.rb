require_relative 'route_record'

module RailsRoutesAnalyzer

  class RouteIssue < RouteRecord
    fields \
      :error,
      :verbose_message,
      :missing_actions

    def issue?
      true
    end

    def human_readable_error
      human_readable_error_message.tap do |message|
        message << "| #{verbose_message}" if verbose_message
      end
    end

    def suggestion(**kwargs)
      error_suggestion(**kwargs).tap do |message|
        message << "| #{verbose_message}" if verbose_message
      end
    end

    def try_to_fix_line(line)
      raise NotImplementedError, 'should be provided by subclasses'
    end
  end

end
