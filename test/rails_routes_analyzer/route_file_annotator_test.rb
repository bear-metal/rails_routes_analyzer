require 'test_helper'

module RailsRoutesAnalyzer
  class RouteFileAnnotatorTest < Minitest::Test
    def setup_annotator(file:)
      Rails.application.routes_reloader.paths.clear
      Rails.application.routes_reloader.paths << Rails.root.join(file)
      analysis = RouteAnalysis.new
      RouteFileAnnotator.new(analysis: analysis)
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
      #File.open('asd.rb', 'w') {|f| f.write annotator.annotated_file_content(file) }
      assert_equal File.read(Rails.root.join('routes_bad-corrected.rb')),
        annotator.annotated_file_content(file)
    end

    def test_annotate_bad_loops_file
      file = Rails.root.join('routes_bad_loops.rb')
      annotator = setup_annotator(file: file)
      assert_equal File.read(Rails.root.join('routes_bad_loops-corrected.rb')),
        annotator.annotated_file_content(file)
    end
  end
end
