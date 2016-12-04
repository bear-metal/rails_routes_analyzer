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

    def annotate_routes_file(filename, inplace: false, do_exit: true)
      filenames = files_to_work_on(filename, inplace: inplace)
      if filenames.kind_of?(Numeric)
        if do_exit
          exit filenames
        else
          return filenames
        end
      end

      filenames.map! { |filename| RailsRoutesAnalyzer.get_full_filename(filename) }

      filenames.each do |filename|
        unless File.exist?(filename)
          $stderr.puts "Can't find routes file: #{filename}"
          exit 1
        end
      end

      if filenames.size != 1 && !inplace
        raise ArgumentError, "got #{filenames.size} files but can annotate only one at a time to stdout"
      end

      filenames.each do |filename|
        if inplace
          if @force_overwrite || self.class.check_file_is_modifiable(filename, report: true)
            content = annotated_file_content(filename)
            File.open(filename, 'w') { |f| f.write content }
          end
        else
          puts annotated_file_content(filename)
        end
      end
    end

    protected

    def log_notice(*args, &block)
      self.class.log_notice(*args, &block)
    end

    def self.log_notice(message=nil, &block)
      return if ENV['RAILS_ENV'] == 'test'
      message ||= block.call if block
      $stderr.puts "# #{message}" if message.present?
    end

    def self.check_file_is_modifiable(filename, report: false, **kwargs)
      unless filename.to_s.starts_with?(Rails.root.to_s)
        log_notice "Refusing to modify files outside Rails root: #{Rails.root.to_s}" if report
        return false
      end

      check_file_git_status(filename, report: report, **kwargs)
    end

    def self.check_file_git_status(filename, report: false, skip_git: false, repo_root: Rails.root.to_s)
      return skip_git if skip_git

      git = nil
      begin
        require 'git'
        git = Git.open(repo_root)
      rescue => e
        log_notice "Couldn't access git repository at Rails root #{repo_root}. #{e.message}" if report
        return false
      end

      repo_relative_filename = filename.to_s.sub("#{repo_root}/", '')

      # This seems to be required to force some kind of git status
      # refresh because without it tests would randomly detect a file
      # as modified by git-status when the file in fact has no changes.
      git.diff.each { |file| }

      if git.status.changed.has_key?(repo_relative_filename)
        log_notice "Refusing to modify '#{repo_relative_filename}' as it has uncommited changes" if report
        return false
      end

      true
    end

    def annotatable_routes_files(inplace:)
      filenames = @analysis.all_unique_issues_file_names

      if inplace && !@force_overwrite
        filenames.select! { |filename| self.class.check_file_is_modifiable(filename) }
      end

      filenames
    end

    def files_to_work_on(filename, inplace:)
      return [filename] if filename.present?

      filenames = annotatable_routes_files(inplace: inplace)

      if filenames.size == 0
        $stderr.puts "All routes are good, nothing to annotate"
        return 0
      elsif filenames.size > 1 && !inplace
        $stderr.puts "Please specify routes file with ROUTES_FILE='path/routes.rb' as you have more than one file with problems:\n  #{filenames.join("\n  ")}"
        return 1
      end
      filenames
    end
  end

end
