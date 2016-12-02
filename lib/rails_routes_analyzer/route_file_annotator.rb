module RailsRoutesAnalyzer

  class RouteFileAnnotator
    def initialize(analysis: RailsRoutesAnalyzer::RouteAnalysis.new, try_to_fix: false, allow_deleting: false)
      @analysis = analysis
      @try_to_fix = try_to_fix
      @allow_deleting = allow_deleting
    end

    def annotated_file_content(route_filename)
      route_lines = @analysis.route_lines_for_file(route_filename)

      if route_lines.none?(&:issues?)
        log_notice { "Didn't find any route issues for file: #{route_filename}, only found issues in files: #{@analysis.all_unique_issues_file_names.join(', ')}" }
      end

      log_notice { "Annotating #{route_filename}" }

      route_lines_map = route_lines.index_by(&:line_number)

      "".tap do |output|
        File.readlines(route_filename).each_with_index do |line, index|
          route_line = route_lines_map[index + 1]

          if route_line
            output << route_line.annotate(line,
                                          try_to_fix:     @try_to_fix,
                                          allow_deleting: @allow_deleting)
          else
            output << line
          end
        end
      end
    end

    def log_notice(message=nil, &block)
      return if ENV['RAILS_ENV'] == 'test'
      message ||= block.call if block
      STDERR.puts "# #{message}" if message.present?
    end

    def annotate_routes_file(filename)
      filename = automatic_filename_for_annotation if filename.blank?
      filename = RailsRoutesAnalyzer.get_full_filename(filename)

      unless File.exist?(filename)
        STDERR.puts "Can't find routes file: #{filename}"
        exit 1
      end

      puts annotated_file_content(filename)
    end

    def automatic_filename_for_annotation
      filenames = @analysis.all_unique_issues_file_names

      if filenames.size == 0
        STDERR.puts "All routes are good, nothing to annotate"
        exit 0
      elsif filenames.size > 1
        STDERR.puts "Please specify file to annotate with ROUTES_ANNOTATE='path/routes.rb' as you have more than one:\n#{filenames.join("\n  ")}"
        exit 1
      end
      filenames.first
    end
  end

end
