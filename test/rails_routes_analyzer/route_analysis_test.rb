require 'test_helper'

module RailsRoutesAnalyzer
  class RouteAnalysisTest < Minitest::Test
    def setup
      Rails.application.routes_reloader.paths.clear
    end

    def rails_3?
      Rails.version =~ /\A3\./
    end

    def setup_clean_routes
      Rails.application.routes_reloader.paths << Rails.root.join('routes_clean.rb')
      analysis = RouteAnalysis.new
    end

    def test_with_no_application_routes
      Rails.application.routes_reloader.paths << Rails.root.join('routes_empty.rb')
      analysis = RouteAnalysis.new

      assert_equal [], analysis.issues
      assert_equal [], analysis.route_log
      assert_equal Set.new, analysis.implemented_routes
    end

    def test_fully_clean_routes_issues
      analysis = setup_clean_routes

      assert_equal [], analysis.issues
    end

    def test_fully_clean_routes_route_log
      analysis = setup_clean_routes

      assert_equal [
        [["routes_clean.rb:2", "root", "home"], "home", :index, (["GET"] unless rails_3?)],
	[["routes_clean.rb:4", "resources", "home"], "home", :show, ["GET"]],
	[["routes_clean.rb:7", "get", "full_items"], "full_items", :custom, ["GET"]],
	[["routes_clean.rb:10", "get", "full_items"], "full_items", :custom_index, ["GET"]],
	[["routes_clean.rb:5", "resources", "full_items"], "full_items", :index, ["GET"]],
	[["routes_clean.rb:5", "resources", "full_items"], "full_items", :create, ["POST"]],
	[["routes_clean.rb:5", "resources", "full_items"], "full_items", :new, ["GET"]],
	[["routes_clean.rb:5", "resources", "full_items"], "full_items", :edit, ["GET"]],
	[["routes_clean.rb:5", "resources", "full_items"], "full_items", :show, ["GET"]],
        ([["routes_clean.rb:5", "resources", "full_items"], "full_items", :update, ["PATCH"]] unless rails_3?),
	[["routes_clean.rb:5", "resources", "full_items"], "full_items", :update, ["PUT"]],
	[["routes_clean.rb:5", "resources", "full_items"], "full_items", :destroy, ["DELETE"]],
      ].compact, analysis.route_log
    end

    def test_fully_clean_routes_implemented_routes
      analysis = setup_clean_routes

      assert_equal Set.new([
        ["HomeController", :index],
        ["HomeController", :show],
        ["FullItemsController", :custom],
        ["FullItemsController", :custom_index],
        ["FullItemsController", :create],
        ["FullItemsController", :destroy],
        ["FullItemsController", :edit],
        ["FullItemsController", :index],
        ["FullItemsController", :new],
        ["FullItemsController", :show],
        ["FullItemsController", :update],
      ].compact), analysis.implemented_routes
    end

    def setup_bad_routes
      Rails.application.routes_reloader.paths << Rails.root.join('routes_bad.rb')
      RouteAnalysis.new
    end

    def test_bad_routes_issues
      analysis = setup_bad_routes

      issues = analysis.issues.index_by(&:file_location)

      expected = RouteCall.new(
        file_location: "routes_bad.rb:4",
        route_creation_method: "resources",
        controller_name: "home",
        controller_class_name: "HomeController",
        action_names: [:create, :destroy, :edit, :index, :new, :show, :update],
        present_actions: [:index, :show],
      )
      expected.add_issue RouteIssue::Resources.new(
                           suggested_param: "only: [:index, :show]")

      assert_equal expected, issues["routes_bad.rb:4"]

      expected = RouteCall.new(
        file_location: "routes_bad.rb:7",
        route_creation_method: "get",
        controller_name: "full_items",
        controller_class_name: "FullItemsController",
        action_names: [:missing_member_action],
      )
      expected.add_issue RouteIssue::NoAction.new(
                           missing_actions: [:missing_member_action])

      assert_equal expected, issues["routes_bad.rb:7"]

      expected = RouteCall.new(
        file_location: "routes_bad.rb:10",
        route_creation_method: "post",
        controller_name: "full_items",
        controller_class_name: "FullItemsController",
        action_names: [:missing_collection_action],
      )
      expected.add_issue RouteIssue::NoAction.new(
                           missing_actions: [:missing_collection_action])

      assert_equal expected, issues["routes_bad.rb:10"]

      expected = RouteCall.new(
        file_location: "routes_bad.rb:15",
        route_creation_method: "get",
        controller_name: "unknown_controller",
        controller_class_name: "UnknownControllerController",
        action_names: [:index],
      )
      expected.add_issue RouteIssue::NoController.new(
                           error: "uninitialized constant UnknownControllerController")

      assert_equal expected, issues["routes_bad.rb:15"]
    end

    def test_bad_routes_route_log
      analysis = setup_bad_routes

      expected = [
	[["routes_bad.rb:2", "root", "home"], "home", :index, (["GET"] unless rails_3?)],
      ] + expected_resources("routes_bad.rb:4") + [
	[["routes_bad.rb:7", "get", "full_items"], "full_items", :missing_member_action, ["GET"]],
	[["routes_bad.rb:10", "post", "full_items"], "full_items", :missing_collection_action, ["POST"]],
	[["routes_bad.rb:5", "resources", "full_items"], "full_items", :create, ["POST"]],
	[["routes_bad.rb:5", "resources", "full_items"], "full_items", :new, ["GET"]],
	[["routes_bad.rb:5", "resources", "full_items"], "full_items", :edit, ["GET"]],
	[["routes_bad.rb:5", "resources", "full_items"], "full_items", :show, ["GET"]],
	([["routes_bad.rb:5", "resources", "full_items"], "full_items", :update, ["PATCH"]] unless rails_3?),
	[["routes_bad.rb:5", "resources", "full_items"], "full_items", :update, ["PUT"]],
	[["routes_bad.rb:13", "resources", "full_items"], "full_items", :index, ["GET"]],
	[["routes_bad.rb:13", "resources", "full_items"], "full_items", :destroy, ["DELETE"]],
	[["routes_bad.rb:15", "get", "unknown_controller"], "unknown_controller", :index, ["GET"]],
	[["routes_bad.rb:18", "get", "unknown_0"], "unknown_0", :index, ["GET"]],
	[["routes_bad.rb:18", "get", "unknown_1"], "unknown_1", :index, ["GET"]]
      ] + expected_resources("routes_bad.rb:20") + expected_resources("routes_bad.rb:21")
      
      assert_equal expected.compact, analysis.route_log
    end

    def expected_resources(path, controller="home")
      [
        [[path, "resources", controller], controller, :index, ["GET"]],
        [[path, "resources", controller], controller, :create, ["POST"]],
        [[path, "resources", controller], controller, :new, ["GET"]],
        [[path, "resources", controller], controller, :edit, ["GET"]],
        [[path, "resources", controller], controller, :show, ["GET"]],
       ([[path, "resources", controller], controller, :update, ["PATCH"]] unless rails_3?),
        [[path, "resources", controller], controller, :update, ["PUT"]],
        [[path, "resources", controller], controller, :destroy, ["DELETE"]],
      ]
    end

    def test_bad_routes_implemented_routes
      analysis = setup_bad_routes

      assert_equal Set.new([
        ["HomeController", :index],
        ["HomeController", :show],
        ["FullItemsController", :create],
        ["FullItemsController", :destroy],
        ["FullItemsController", :edit],
        ["FullItemsController", :index],
        ["FullItemsController", :new],
        ["FullItemsController", :show],
        ["FullItemsController", :update],
      ]), analysis.implemented_routes
    end

    def setup_bad_loops_routes
      Rails.application.routes_reloader.paths << Rails.root.join('routes_bad_loops.rb')
      RouteAnalysis.new
    end

    def test_bad_loops_issues
      analysis = setup_bad_loops_routes

      issues = analysis.issues.group_by(&:file_location)

      issues_for_3 = issues["routes_bad_loops.rb:3"]
      assert_equal 1, issues_for_3.size
      expected = RouteCall.new(
        file_location: "routes_bad_loops.rb:3",
	route_creation_method: "resource",
	controller_name: "somethings",
	controller_class_name: "SomethingsController",
	action_names: [:destroy],
      )
      expected.add_issue RouteIssue::NoController.new(
                           error: "uninitialized constant SomethingsController")
      assert_equal expected, issues_for_3[0]

      issues_for_7 = issues["routes_bad_loops.rb:7"]

      expected = RouteCall.new(
        file_location: "routes_bad_loops.rb:7",
        route_creation_method: "get",
        controller_name: "home",
        controller_class_name: "HomeController",
        action_names: [:index, :other_action, :unknown_action],
        present_actions: [:index],
      )
      expected.add_issue RouteIssue::NoAction.new(
                           missing_actions: [:other_action, :unknown_action])

      assert_equal expected, issues_for_7[0]
    end
  end
end
