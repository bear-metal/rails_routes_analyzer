module RailsRoutesAnalyzer

  class RouteFileAnnotator
    def initialize(analysis: RailsRoutesAnalyzer::RouteAnalysis.new, try_to_fix: false, allow_deleting: false)
      @analysis = analysis
      @try_to_fix = try_to_fix
      @allow_deleting = allow_deleting
    end

    def annotated_file_content(route_filename)
      relevant_issues = @analysis.all_issues_for_file_name(route_filename)

      if relevant_issues.none?(&:issue?)
        log_notice { "Didn't find any route issues for file: #{route_filename}, only have references to: #{@analysis.all_unique_issues_file_names.join(', ')}" }
      end

      log_notice { "Annotating #{route_filename}" }

      lines = File.readlines(route_filename)
      issue_map = relevant_issues.group_by { |issue| issue.line_number }

      "".tap do |output|
        File.readlines(route_filename).each_with_index do |line, index|
          issues = issue_map[index + 1]

          if @try_to_fix
            output << try_to_fix_line(line, issues)
          else
            output << add_suggestions_to(line, issues)
          end
        end
      end
    end

    def try_to_fix_line(line, issues)
      has_one_issue = issues.size == 1 && issues[0].issue?

      if has_one_issue && (fixed_line = issues[0].try_to_fix_line(line)) && (@allow_deleting || fixed_line != '')
        fixed_line
      else
        add_suggestions_to(line, issues)
      end
    end

    def add_suggestions_to(line, issues)
      suggestions = combined_suggestion_for(issues)

      if suggestions.present?
        line.sub(/( # SUGGESTION.*)?$/, " # SUGGESTION #{suggestions}")
      else
        line
      end
    end

    def log_notice(message=nil, &block)
      return if ENV['RAILS_ENV'] == 'test'
      message ||= block.call if block
      STDERR.puts "# #{message}" if message.present?
    end

    def combined_suggestion_for(all_issues)
      return if all_issues.nil? || all_issues.none?(&:issue?)

      issues, non_issues = all_issues.partition(&:issue?)

      context = {
        non_issues: non_issues.present?,
        num_controllers: all_issues.map(&:controller_class_name).uniq.count,
      }

      issues.map { |issue| issue.suggestion(**context) }.join(', ')
    end

    def annotate_routes_file(filename)
      filenames = @analysis.unique_issues_file_names

      if filename.blank?
        if filenames.size == 0
          STDERR.puts "All routes are good, nothing to annotate"
          exit 0
        elsif filenames.size > 1
          STDERR.puts "Please specify file to annotate with ROUTES_ANNOTATE='path/routes.rb' as you have more than one:\n#{filenames.join("\n  ")}"
          exit 1
        end
        filename = filenames.first
      end

      filename = RailsRoutesAnalyzer.get_full_filename(filename)

      unless File.exist?(filename)
        STDERR.puts "Can't find routes file: #{filename}"
        exit 1
      end

      puts annotated_file_content(filename)
    end
  end

end
