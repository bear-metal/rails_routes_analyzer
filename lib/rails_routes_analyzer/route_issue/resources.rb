require_relative 'base'

module RailsRoutesAnalyzer
  module RouteIssue

    class Resources < Base
      fields :suggested_param

      def human_readable_error_message
        "`#{route_creation_method}' call at #{file_location} for #{controller_class_name} should use #{suggested_param}"
      end

      def error_suggestion(non_issues:, num_controllers:)
        "use #{suggested_param}".tap do |message|
          if num_controllers > 1
            message << " only for #{controller_class_name}"
          end
        end
      end

      def try_to_fix_line(line)
        try_to_fix_resources_line(line, suggested_param)
      end

      def get_verbose_message
        "This route currently covers unimplemented actions: #{format_actions(missing_actions.sort)}"
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

      def try_to_fix_line(line, suggestion: suggested_param)
        self.class.try_to_fix_resources_line(line, suggestion)
      end

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
end
