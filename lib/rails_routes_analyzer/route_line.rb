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

    def present_actions?
      records.any?(&:present_actions?)
    end

    def issues
      @issues ||= records.select(&:issue?)
    end

    def issues?
      issues.any?
    end

    def annotate(line, try_to_fix:, allow_deleting:)
      suggestions = combined_suggestions
      if try_to_fix && !(fix_for_line = try_to_fix_line(line, allow_deleting: allow_deleting,
                                                              suggestion_comment: "# SUGGESTION #{suggestions}")).nil?
        fix_for_line
      else
        add_suggestions_to(line, suggestions)
      end
    end

    # Try to generate an automatic fix for the line, this does not
    # apply to lines with multiple issues (iterations) as those
    # will most likely require changes to the surrounding code.
    def try_to_fix_line(line, allow_deleting:, suggestion_comment:)
      has_one_issue = issues.size == 1
      has_one_iteration = records.size == 1

      return unless has_one_issue && has_one_iteration

      fix = issues[0].try_to_fix_line(line)

      return unless fix.present? || (fix == '' && allow_deleting && safely_deletable_line?(line))

      fix.gsub(suggestion_comment, '').gsub(/\ +$/, '')
    end

    # Should avoid deleting lines that look like they might start a block because
    # we're not smart enough to also be able to delete the end of that block.
    def safely_deletable_line?(line)
      line !~ /( do |{)/
    end

    def add_suggestions_to(line, suggestions)
      line.sub(/( # SUGGESTION.*)?$/,
               suggestions.present? ? " # SUGGESTION #{suggestions}" : "")
    end

    def all_controller_class_names
      records.map(&:controller_class_name).uniq
    end

    def combined_suggestions
      return unless issues?

      context = {
        has_present_actions: present_actions?,
        num_controllers:     all_controller_class_names.count,
      }

      issues.map { |issue| issue.suggestion(**context) }.flatten.join(', ')
    end

  end

end
