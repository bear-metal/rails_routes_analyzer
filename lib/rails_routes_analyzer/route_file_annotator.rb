module RailsRoutesAnalyzer

  class RouteFileAnnotator
    def initialize(analysis:)
      @analysis = analysis
    end

    def annotated_file_content(route_filename)
      relevant_issues = @analysis.issues_for_file_name(route_filename)

      if relevant_issues.empty?
        STDERR.puts "Didn't find any route issues for file: #{route_filename}, only have references to: #{@analysis.unique_issues_file_names.join(', ')}"
      end

      STDERR.puts "Annotating #{route_filename}"

      lines = File.readlines(route_filename)
      issue_map = relevant_issues.group_by { |issue| issue.line_number }

      "".tap do |output|
        File.readlines(route_filename).each_with_index do |line, index|
          issues = (issue_map[index + 1] || []).map(&:suggestion).compact.uniq.join(', ')
          if issues.present?
            output << line.sub(/$/, " # SUGGESTION #{issues}")
          else
            output << line
          end
        end
      end
    end

    def annotate_routes_file(filename_or_one)
      filenames = @analysis.unique_issues_file_names

      if filename_or_one == '1'
        if filenames.size > 1
          STDERR.puts "Please specify file to annotate as you have more than one: #{filenames.join(', ')}"
          exit 1
        end
        filename = filenames.first
      else
        filename = filename_or_one
      end

      filename = RailsRoutesAnalyzer.get_full_filename(filename)

      unless File.exists?(filename)
        STDERR.puts "Can't routes find file: #{filename}"
        exit 1
      end

      puts annotated_file_content(filename)
    end
  end

end
