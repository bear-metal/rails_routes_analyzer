module RailsRoutesAnalyzer

  class RouteFileAnnotator
    # @param try_to_fix [Boolean] should automatic fixes be attempted
    # @param allow_deleting [Boolean] should route lines be deleted when they match no actions
    # @param force_overwrite [Boolean] allow overwriting routes file even if it has uncommited changes or is outside Rails.root
    def initialize(try_to_fix: false, allow_deleting: false, force_overwrite: false, analysis: nil, **kwargs)
      @analysis = analysis || RailsRoutesAnalyzer::RouteAnalysis.new(**kwargs)
      @try_to_fix = try_to_fix
      @allow_deleting = allow_deleting
      @force_overwrite = force_overwrite
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

    def annotate_routes_file(filename, inplace: false)
      filenames = files_to_work_on(filename, inplace: inplace)
      filenames.map! { |filename| RailsRoutesAnalyzer.get_full_filename(filename) }

      filenames.each do |filename|
        unless File.exist?(filename)
          STDERR.puts "Can't find routes file: #{filename}"
          exit 1
        end
      end

      if filenames.size != 1 && !inplace
        raise ArgumentError, "got #{filenames.size} files but can annotate only one at a time to stdout"
      end

      filenames.each do |filename|
        if inplace
          if @force_overwrite || check_file_is_modifiable(filename)
            content = annotated_file_content(filename)
            File.open(filename, 'w') { |f| f.write content }
          end
        else
          puts annotated_file_content(filename)
        end
      end
    end

    def check_file_is_modifiable(filename, report: true)
      unless filename.starts_with?(Rails.root.to_s)
        STDERR.puts "Refusing to modify files outside Rails root: #{Rails.root.to_s}" if report
        return false
      end

      git = nil
      begin
        require 'git'
        git = Git.open(Rails.root.to_s)
      rescue => e
        STDERR.puts "Couldn't access git repository at Rails root #{Rails.root.to_s}. #{e.message}" if report
        return false
      end

      rails_relative_filename = filename.sub("#{Rails.root}/", '')

      if git.status.changed.has_key?(rails_relative_filename)
        STDERR.puts "Refusing to modify '#{rails_relative_filename}' as it has uncommited changes" if report
        return false
      end

      true
    end

    def annotatable_routes_files
      filenames = @analysis.all_unique_issues_file_names

      unless @force_overwrite
        filenames.select! { |filename| check_file_is_modifiable?(filename, report: false) }
      end

      filenames
    end

    def files_to_work_on(filename, inplace:)
      return filename if filename.present?

      filenames = annotatable_routes_files

      if filenames.size == 0
        STDERR.puts "All routes are good, nothing to annotate"
        exit 0
      elsif filenames.size > 1 && !inplace
        STDERR.puts "Please specify routes file with ROUTES_FILE='path/routes.rb' as you have more than one file with problems:\n  #{filenames.join("\n  ")}"
        exit 1
      end
      filenames
    end
  end

end
