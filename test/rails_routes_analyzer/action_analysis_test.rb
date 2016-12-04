require 'test_helper'

module RailsRoutesAnalyzer
  class ActionAnalysisTest < Minitest::Test

    def setup
      Rails.application.routes_reloader.paths.clear
    end

    def setup_clean_routes
      Rails.application.routes_reloader.paths << Rails.root.join('routes_clean.rb')
    end

    def get_action_analysis(gem_name: nil, **kwargs)
      GemManager.stub :identify_gem, gem_name do
        ActionAnalysis.new(**kwargs)
      end
    end

    def get_action_report(gem_name: nil, **kwargs)
      analysis = get_action_analysis(gem_name: gem_name, **kwargs)
      analysis.all_action_methods
    end

    def test_analyze_action_methods
      report = get_action_report

      expected = [
        ["HomeController",            :index],
        ["HomeController",            :show],
        ["FullItemsController",       :create],
        ["FullItemsController",       :custom],
        ["FullItemsController",       :custom_index],
        ["FullItemsController",       :destroy],
        ["FullItemsController",       :edit],
        ["FullItemsController",       :index],
        ["FullItemsController",       :new],
        ["FullItemsController",       :show],
        ["FullItemsController",       :update],
        ["ControllerIncludingModule", :module_provided_action],
        ["SubclassHomeController",    :index],
        ["SubclassHomeController",    :show],
        ["SubclassHomeController",    :subclass_action]
      ]
      assert_report expected, report
    end

    def test_analyze_action_methods_with_no_application_routes
      report = get_action_report

      assert report.all?(&:route_missing)
    end

    def test_analyze_action_methods_with_clean_routes
      setup_clean_routes
      report = get_action_report.select(&:route_missing)

      expected = [
        ["ControllerIncludingModule", :module_provided_action],
        ["SubclassHomeController",    :index],
        ["SubclassHomeController",    :show],
        ["SubclassHomeController",    :subclass_action]
      ]
      assert_report expected, report
    end

    def test_analyze_action_methods_is_inherited
      report = get_action_report.select(&:is_inherited)

      expected = [
        ["SubclassHomeController", :index],
        ["SubclassHomeController", :show],
      ]
      assert_report expected, report

      assert_equal [HomeController], report.map(&:owner).uniq
    end

    def test_analyze_action_methods_from_module
      report = get_action_report.select(&:from_module)

      expected = [
        ["ControllerIncludingModule", :module_provided_action],
      ]
      assert_report expected, report

      assert_equal ModuleWithAction, report[0].owner
    end

    def test_analyze_action_methods_from_gem
      report = get_action_report(gem_name: "random_gem")

      assert_equal ["random_gem"], report.map(&:from_gem).uniq
    end

    EXPECTED_REPORT_PREAMBLE = <<-EOF.strip_heredoc + ActionAnalysis::PREAMBLE_WARNING
      Controllers with no routes pointing to them:
        SubclassHomeController

    EOF

    EXPECTED_REPORT_PREAMBLE_WITH_GEM_CONTROLLERS = <<-EOF.strip_heredoc + ActionAnalysis::PREAMBLE_WARNING
      Controllers with no routes pointing to them:
        ControllerIncludingModule
        EmptyController
        SubclassHomeController

    EOF

    def test_routes_report_with_clean_routes
      setup_clean_routes
      report = get_action_analysis

      expected = EXPECTED_REPORT_PREAMBLE + <<-EOF.strip_heredoc
        ApplicationController
          HomeController
            SubclassHomeController
              subclass_action @ ./application.rb:56
      EOF

      stdout, _ = capture_io { report.print_report }
      assert_equal expected, stdout
    end

    def test_routes_report_with_clean_routes_with_metadata_modules_duplicates
      ApplicationController.broken_action_methods = true
      setup_clean_routes
      report = get_action_analysis(metadata: true, report_modules: true, report_duplicates: true)

      expected = EXPECTED_REPORT_PREAMBLE + <<-EOF.strip_heredoc
        ApplicationController
          Actions:
            second_non_action @ ./application.rb:20 no-route
          ControllerIncludingModule
            module_provided_action @ ./application.rb:64 no-route module:ModuleWithAction
          HomeController
            SubclassHomeController
              index           @ ./application.rb:36 no-route inherited:HomeController
              show            @ ./application.rb:39 no-route inherited:HomeController
              subclass_action @ ./application.rb:56 no-route
      EOF

      stdout, _ = capture_io { report.print_report }
      assert_equal expected, stdout
    ensure
      ApplicationController.broken_action_methods = false
    end

    def test_routes_report_with_clean_routes_with_duplicate_reporting
      setup_clean_routes
      report = get_action_analysis(report_duplicates: true)

      expected = EXPECTED_REPORT_PREAMBLE + <<-EOF.strip_heredoc
        ApplicationController
          HomeController
            SubclassHomeController
              index           @ ./application.rb:36
              show            @ ./application.rb:39
              subclass_action @ ./application.rb:56
      EOF

      stdout, _ = capture_io { report.print_report }
      assert_equal expected, stdout
    end

    def test_build_action_report_with_gem_actions
      setup_clean_routes
      report = get_action_analysis(gem_name: 'random_gem', report_gems: false)

      expected = "There are no actions without a route\n"

      stdout, _ = capture_io { report.print_report }
      assert_equal expected, stdout

      report = get_action_analysis(gem_name: 'random_gem', report_gems: true)

      expected = EXPECTED_REPORT_PREAMBLE_WITH_GEM_CONTROLLERS + <<-EOF.strip_heredoc
        ApplicationController
          HomeController
            SubclassHomeController
              subclass_action @ ./application.rb:56
      EOF

      stdout, _ = capture_io { report.print_report }
      assert_equal expected, stdout
    end

    protected

    def assert_report(expected, report)
      assert_equal expected.sort,
                   report.map { |action|
                     [ action.controller_name, action.action_name  ]
                   }.sort
    end
  end
end
