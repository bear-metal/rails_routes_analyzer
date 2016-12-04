require 'test_helper'

module RailsRoutesAnalyzer
  class RouteFileAnnotatorTest < Minitest::Test
    def setup_annotator(file:, **kwargs)
      Rails.application.routes_reloader.paths.clear

      Array.wrap(file).each do |f|
        Rails.application.routes_reloader.paths << Rails.root.join(f)
      end

      analysis = RouteAnalysis.new
      RouteFileAnnotator.new(analysis: analysis, **kwargs)
    end

    def test_annotate_empty_file
      file = Rails.root.join('routes_empty.rb')
      annotator = setup_annotator(file: file)
      assert_equal File.read(file), annotator.annotated_file_content(file)
    end

    def test_annotate_empty_file_without_last_newline
      file = Rails.root.join('routes_empty_without_last_newline.rb')
      annotator = setup_annotator(file: file)
      assert_equal File.read(file), annotator.annotated_file_content(file)
    end

    def test_annotate_clean_file
      file = Rails.root.join('routes_clean.rb')
      annotator = setup_annotator(file: file)
      assert_equal File.read(file), annotator.annotated_file_content(file)
    end

    def test_annotate_bad_file
      file = Rails.root.join('routes_bad.rb')
      annotator = setup_annotator(file: file)
      assert_equal File.read(Rails.root.join('routes_bad-annotated.rb')),
        annotator.annotated_file_content(file)
    end

    def test_annotate_bad_loops_file
      file = Rails.root.join('routes_bad_loops.rb')
      annotator = setup_annotator(file: file)
      assert_equal File.read(Rails.root.join('routes_bad_loops-annotated.rb')),
        annotator.annotated_file_content(file)
    end

    def test_annotate_routes_file_empty_file
      file = Rails.root.join('routes_empty.rb')
      annotator = setup_annotator(file: file)

      stdout, stderr = capture_io { annotator.annotate_routes_file(file, do_exit: false) }

      assert_equal File.read(file), stdout
      assert_equal "", stderr
    end

    def test_annotate_routes_file_empty_file_without_specifying_file_name
      file = Rails.root.join('routes_empty.rb')
      annotator = setup_annotator(file: file)

      stdout, stderr = capture_io do
        assert_equal 0, annotator.annotate_routes_file('', do_exit: false)
      end

      assert_equal "", stdout
      assert_equal "All routes are good, nothing to annotate\n", stderr
    end

    def test_annotate_routes_file_multiple_route_files_without_specifying_file_name
      file1 = Rails.root.join('routes_bad.rb')
      file2 = Rails.root.join('routes_bad_loops.rb')
      annotator = setup_annotator(file: [file1, file2], force_overwrite: true)

      stdout, stderr = capture_io do
        assert_equal 1, annotator.annotate_routes_file('', do_exit: false)
      end

      assert_equal "", stdout
      assert_equal "Please specify routes file with ROUTES_FILE='path/routes.rb' as you have more than one file with problems:\n  #{file1.to_s}\n  #{file2.to_s}\n", stderr
    end

    def test_annotate_bad_routes_file_inplace
      file = Rails.root.join('routes_bad.rb')
      tmp_file = Rails.root.join('tmp/routes_bad.rb')
      FileUtils.cp file, tmp_file

      annotator = setup_annotator(file: tmp_file, force_overwrite: true)

      stdout, stderr = capture_io do
        annotator.annotate_routes_file(tmp_file, inplace: true, do_exit: false)
      end

      assert_equal File.read(Rails.root.join('routes_bad-annotated.rb')), File.read(tmp_file)
      assert_equal "", stderr
    end

    def test_correct_bad_routes_file_inplace
      file = Rails.root.join('routes_bad.rb')
      tmp_file = Rails.root.join('tmp/routes_bad.rb')
      FileUtils.cp file, tmp_file

      annotator = setup_annotator(file: tmp_file, force_overwrite: true, try_to_fix: true, allow_deleting: true)

      stdout, stderr = capture_io do
        annotator.annotate_routes_file(tmp_file, inplace: true, do_exit: false)
      end

      assert_equal File.read(Rails.root.join('routes_bad-corrected.rb')), File.read(tmp_file)
      assert_equal "", stderr
    end

    def test_check_file_is_modifiable
      original = Rails.root.join('routes_bad-original-for-git-test.rb')
      file     = Rails.root.join('routes_bad-for-git-test.rb')

      assert RouteFileAnnotator.check_file_is_modifiable(file, skip_git: true)

      # NOTE assumption is that the gem tests are run within a git repo
      this_gem_root = File.expand_path('../../..', __FILE__)

      original_content = File.read(original)
      File.open(file, 'w') { |f| f.write original_content }

      if File.exist?(File.join(this_gem_root, '.git'))
        assert RouteFileAnnotator.check_file_is_modifiable(file, repo_root: this_gem_root)

        File.open(file, 'w') { |f| f.write(original_content + ' # comment') }

        refute RouteFileAnnotator.check_file_is_modifiable(file, repo_root: this_gem_root)
      else
        $stderr.puts "NOTE: skipping git-dependent test as there is no .git repository at #{this_gem_root}"
      end
    ensure
      File.open(file, 'w') { |f| f.write original_content }
    end
  end
end
