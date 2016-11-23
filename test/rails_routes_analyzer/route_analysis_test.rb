require 'test_helper'

module RailsRoutesAnalyzer
  class RouteAnalysisTest < Minitest::Test
    def setup
      Rails.application.routes_reloader.paths.clear
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
	["home", :index],
	["home", :show],
	["full_items", :custom],
	["full_items", :custom_index],
	["full_items", :index],
	["full_items", :create],
	["full_items", :new],
	["full_items", :edit],
	["full_items", :show],
	["full_items", :update],
	["full_items", :update],
	["full_items", :destroy],
      ], analysis.route_log
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
      ]), analysis.implemented_routes
    end

    def setup_bad_routes
      Rails.application.routes_reloader.paths << Rails.root.join('routes_bad.rb')
      RouteAnalysis.new
    end

    def test_bad_routes_issues
      analysis = setup_bad_routes

      issues = analysis.issues.index_by(&:file_location)

      assert_equal RouteIssue.new(
        file_location: "routes_bad.rb:4",
        route_creation_method: "resources",
        controller_name: "home",
        controller_class_name: "HomeController",
        action_names: [:create, :destroy, :edit, :index, :new, :show, :update],
        error: nil,
        type: :suggestion,
        suggestion: "only: [:index, :show]",
      ), issues["routes_bad.rb:4"]

      assert_equal RouteIssue.new(
        file_location: "routes_bad.rb:7",
        route_creation_method: "get",
        controller_name: "full_items",
        controller_class_name: "FullItemsController",
        action_names: [:missing_member_action],
        error: nil,
        type: :no_action,
        action: :missing_member_action,
        suggestion: "action :missing_member_action not found for FullItemsController",
      ), issues["routes_bad.rb:7"]

      assert_equal RouteIssue.new(
        file_location: "routes_bad.rb:10",
        route_creation_method: "post",
        controller_name: "full_items",
        controller_class_name: "FullItemsController",
        action_names: [:missing_collection_action],
        error: nil,
        type: :no_action,
        action: :missing_collection_action,
        suggestion: "action :missing_collection_action not found for FullItemsController",
      ), issues["routes_bad.rb:10"]

      assert_equal RouteIssue.new(
        file_location: "routes_bad.rb:15",
        route_creation_method: "get",
        controller_name: "unknown_controller",
        controller_class_name: "UnknownControllerController",
        action_names: [:index],
        error: "uninitialized constant UnknownControllerController",
        type: :no_controller,
        suggestion: "delete, UnknownControllerController not found",
      ), issues["routes_bad.rb:15"]

      p issues.keys
    end

    def test_bad_routes_route_log
      analysis = setup_bad_routes

      assert_equal [
        ["home", :index],
	["home", :index],
	["home", :create],
	["home", :new],
	["home", :edit],
	["home", :show],
	["home", :update],
	["home", :update],
	["home", :destroy],
	["full_items", :missing_member_action],
	["full_items", :missing_collection_action],
	["full_items", :create],
	["full_items", :new],
	["full_items", :edit],
	["full_items", :show],
	["full_items", :update],
	["full_items", :update],
	["full_items", :index],
	["full_items", :destroy],
	["unknown_controller", :index],
      ], analysis.route_log
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
      assert_equal RouteIssue.new(
        file_location: "routes_bad_loops.rb:3",
	route_creation_method: "resource",
	controller_name: "somethings",
	controller_class_name: "SomethingsController",
	action_names: [:destroy],
	error: "uninitialized constant SomethingsController",
	type: :no_controller,
	suggestion: "delete, SomethingsController not found",
      ), issues_for_3[0]

      issues_for_7 = issues["routes_bad_loops.rb:7"].group_by(&:action)
      assert_equal 2, issues_for_7.size

      assert_equal RouteIssue.new(
        file_location: "routes_bad_loops.rb:7",
        route_creation_method: "get",
        controller_name: "home",
        controller_class_name: "HomeController",
        action_names: [:index, :other_action, :unknown_action],
        error: nil,
        type: :no_action,
        action: :other_action,
        suggestion: "action :other_action not found for HomeController",
      ), issues_for_7[:other_action][0]

      assert_equal RouteIssue.new(
        file_location: "routes_bad_loops.rb:7",
        route_creation_method: "get",
        controller_name: "home",
        controller_class_name: "HomeController",
        action_names: [:index, :other_action, :unknown_action],
        error: nil,
        type: :no_action,
        action: :unknown_action,
        suggestion: "action :unknown_action not found for HomeController",
      ), issues_for_7[:unknown_action][0]
    end
  end
end
