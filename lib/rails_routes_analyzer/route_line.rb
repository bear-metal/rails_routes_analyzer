module RailsRoutesAnalyzer

  # Represents a single line in Rails routes file with all
  # the collected information about that line.
  class RouteLine

    attr_reader :full_filename, :line_number, :records

    def initialize(full_filename:, line_number:, records:)
      @full_filename = full_filename
      @line_number   = line_number
      @records       = records
    end

    def file_location
      @file_location ||= "#{full_filename}:#{line_number}"
    end

    def has_present_actions?
      records.any?(&:has_present_actions?)
    end

    def issues
      @issues ||= records.select(&:issue?)
    end

    def issues?
      issues.any?
    end

    def annotate(line, try_to_fix:, allow_deleting:)
      if try_to_fix && !(fix_for_line = try_to_fix_line(line, allow_deleting: allow_deleting)).nil?
        fix_for_line
      else
        add_suggestions_to(line)
      end
    end

    # Try to generate an automatic fix for the line, this does not
    # apply to lines with multiple issues (iterations) as those
    # will most likely require changes to the surrounding code.
    def try_to_fix_line(line, allow_deleting:)
      has_one_issue = issues.size == 1

      if has_one_issue && !has_present_actions?
        fix = issues[0].try_to_fix_line(line)
        return fix if fix.present? || (fix == '' && allow_deleting)
      end
    end

    def add_suggestions_to(line)
      suggestions = combined_suggestions

      line.sub(/( # SUGGESTION.*)?$/,
               suggestions.present? ? " # SUGGESTION #{suggestions}" : "")
    end

    def all_controller_class_names
      records.map(&:controller_class_name).uniq
    end

    def combined_suggestions
      return unless issues?

      context = {
        has_present_actions: has_present_actions?,
        num_controllers:     all_controller_class_names.count,
      }

      issues.map { |issue| issue.suggestion(**context) }.flatten.join(', ')
    end

  end

end
