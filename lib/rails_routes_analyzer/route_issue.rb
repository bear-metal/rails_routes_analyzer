module RailsRoutesAnalyzer

  class RouteIssue < Hash
    %i[
      action
      action_names
      missing_actions
      present_actions
      controller_class_name
      controller_name
      error
      file_location
      route_creation_method
      suggested_param
      type
      verbose_message
    ].each do |name|
      define_method(name) { self[name] }
    end

    def initialize(opts={})
      self.update(opts)
    end

    def issue?
      type != :non_issue
    end

    def resource?
      type == :resources
    end

    def full_filename
      RailsRoutesAnalyzer.get_full_filename(file_location.sub(/:[0-9]*\z/, ''))
    end

    def line_number
      file_location[/:([0-9]+)\z/, 1].to_i
    end

    def human_readable
      case self[:type]
      when :non_issue
        ''
      when :no_controller
        "`#{route_creation_method}' call at #{file_location} there is no controller: #{controller_class_name} for '#{controller_name}' (actions: #{action_names.inspect})".tap do |msg|
          msg << " error: #{error}" if error.present?
        end
      when :no_action
        missing_actions.map do |action|
          "`#{route_creation_method} :#{action}' call at #{file_location} there is no matching action in #{controller_class_name}"
        end.tap do |result|
          return nil if result.size == 0
          return result[0] if result.size == 1
        end
      when :resources
        "`#{route_creation_method}' call at #{file_location} for #{controller_class_name} should use #{suggested_param}"
      else
        raise ArgumentError, "Unknown issue_type: #{self[:type].inspect}"
      end.tap do |message|
        message << "| #{verbose_message}" if verbose_message
      end
    end

    def suggestion(non_issues:, num_controllers:)
      case self[:type]
      when :non_issue
        nil
      when :no_controller
        if non_issues
          "remove case for #{controller_class_name} as it doesn't exist"
        else
          "delete, #{controller_class_name} not found"
        end
      when :no_action
        actions = format_actions(missing_actions)
        if non_issues
          "remove case#{'s' if missing_actions.size > 1} for #{actions}"
        else
          "delete line, #{actions} matches nothing"
        end.tap do |message|
          message << " for controller #{controller_class_name}" if num_controllers > 1
        end
      when :resources
        "use #{suggested_param}".tap do |message|
          if num_controllers > 1
            message << " only for #{controller_class_name}"
          end
        end
      else
        raise ArgumentError, "Unknown issue_type: #{self[:type].inspect}"
      end.tap do |message|
        message << "| #{verbose_message}" if verbose_message
      end
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

    # Returns the routes line with the fix suggested in this RouteIssue but only if the fix
    # is successfully applied. Line deleting fixes result in a blank string (with no line break)
    def try_to_fix_line(line)
      case self[:type]
      when :non_issue
        line
      when :no_controller
        if non_issues
          nil # Unable to fix complex cases
        else
          '' # Delete
        end
      when :no_action
        if non_issues
          nil # Unable to fix complex cases
        else
          '' # Delete
        end
      when :resources
        if num_controllers == 1
          self.class.try_to_fix_resources_line(line, suggested_param)
        else
          nil # Can't fix resource(s) calls covering multiple controllers in a loop
        end
      else
        raise ArgumentError, "Unknown issue_type: #{self[:type].inspect}"
      end
    end

    # This is horrible but just maybe works well enough most of the time to be useful.
    RESOURCES_PARSE_REGEX = %r%
      \A
      (?<beginning>       # contains the part that looks like:  resources :some_things
        \s*
        resources?
        \(?
        \s*
        :\w+              # the name of the resource as a symbol
      )
      (?<separator>,\s*)? # something optional that separates "resources :some_things" from its parameters
      (?<params>.*?)      # all the parameters whatever they might be, if present at all
      (?<end>
        \)?
        (\s+(do|{))?      # optional block, either " do" or " {"
        [\t ]*            # any whitespace, except linebreak (not sure why it's matched without 'm' modifier here)
      )
      $
    %x

    ONLY_EXCEPT_PARAM_REGEX = %r%
      (
        (:(?<key>only|except)\s*=>)  # ":only =>" or ":except =>"
        |
        (?<key>only|except):         # "only:" or "except:"
      )
      \s*
      (
        \[[^\]]*\]  # anything between [ and ]
        |
        :\w+        # or a symbol
      )
    %x

    RESOURCE_OTHER_PARAM_REGEX = %r%
      (
        (:(?<key>\w+)\s*=>)
        |
        (?<key>\w+):
      )
      \s*
      (
        \[[^\]]*\]  # anything between [ and ]
        |
        :\w+        # or a symbol
        |
        '[^']*'     # a limited single-quote string
        |
        "[^"]*"     # a limited double-quote string
        |
        true
        |
        false
      )
    %x

    def self.try_to_fix_resources_line(line, suggestion)
      data = line.match(RESOURCES_PARSE_REGEX)
      line_break = line[/$(.*)\z/m, 1]

      if data
        separator = data[:separator].presence || ', '

        params = if [nil, ''].include?(data[:params])
          suggestion
        elsif (existing = data[:params][ONLY_EXCEPT_PARAM_REGEX]).present?
          # We get here if the only/except parameter already exists and
          # our only task is to replace it, should generally be ok.
          data[:params].sub(existing, suggestion)
        elsif does_params_look_like_a_safe_hash?(data[:params])
          # If params looks like a hash it should be safe to append the suggestion
          "#{data[:params]}, #{suggestion}"
        elsif match = data[:params].match(/\A(?<opening>\s*{\s*)(?<inner_data>.*?)(?<closing>\s*}\s*)\z/)
          # If params looks like a safe hash between { and } then add they key inside the hash
          if does_params_look_like_a_safe_hash?(match[:inner_data])
            "#{match[:opening]}#{match[:inner_data]}, #{suggestion}#{match[:closing]}"
          end
        end

        if params
          "#{data[:beginning]}#{separator}#{params}#{data[:end]}#{line_break}"
        end
      end
    end

    # Check if the parameter string contains only a limited set of known
    # resource hash keys in which case it should generally be safe to
    # append only:/except: to it.
    def self.does_params_look_like_a_safe_hash?(params)
      return false if params =~ /[{}]/ # definitely can't handle: "resources :name, { key: val }"

      # Replace all known "key: simple_value" pairs with 'X'
      result = params.gsub(RESOURCE_OTHER_PARAM_REGEX, 'X')

      # Remove all whitespace
      result.gsub!(/\s/, '')

      # check that the result string looks like: "X" or "X,X", "X,X,X" depending on how many parameters there were
      result.split(',').uniq == %w[ X ]
    end
  end

end
