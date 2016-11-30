require 'test_helper'

module RailsRoutesAnalyzer
  class RouteIssueTest < Minitest::Test
    def setup_route_issues(file: 'routes_bad.rb')
      Rails.application.routes_reloader.paths.clear
      Rails.application.routes_reloader.paths << Rails.root.join(file)
      RouteAnalysis.new
    end

    def get_issue_at(location)
      file, line = location.split(':')

      analysis = setup_route_issues(file: file)
      analysis.issues.detect do |issue|
        issue.file_location == location
      end or raise("Failed to find issue at #{location}, found at: #{analysis.issues.map(&:file_location).join(', ')}")
    end

    def test_resources_action_limit_suggestion
      issue = get_issue_at 'routes_bad.rb:4'
      assert_equal "`resources' call at routes_bad.rb:4 for HomeController should use only: [:index, :show]", issue.human_readable_error
      assert_equal 4, issue.line_number
      assert_equal File.expand_path('../../dummy/routes_bad.rb', __FILE__), issue.full_filename
    end

    def test_custom_member_route_without_action_method
      issue = get_issue_at 'routes_bad.rb:7'
      assert_equal "`get :missing_member_action' call at routes_bad.rb:7 there is no matching action in FullItemsController", issue.human_readable_error
    end

    def test_custom_collection_route_without_action_method
      issue = get_issue_at 'routes_bad.rb:10'
      assert_equal "`post :missing_collection_action' call at routes_bad.rb:10 there is no matching action in FullItemsController", issue.human_readable_error
    end

    def test_unknown_controller
      issue = get_issue_at 'routes_bad.rb:15'
      assert_equal "`get' call at routes_bad.rb:15 there is no controller: UnknownControllerController for 'unknown_controller' (actions: [:index]) error: uninitialized constant UnknownControllerController", issue.human_readable_error
    end

    def test_try_to_fix_resources_line
      # 1. No block
      # 1.1 Without parentheses
      assert_replacement "resources :some_random, only: [:asd]",
                         "resources :some_random"

      assert_replacement "  	resources :some_random, only: [:asd] 	",
                         "  	resources :some_random 	"

      # 1.2 With parentheses
      assert_replacement "resources(:some_random, only: [:asd])",
                         "resources(:some_random)"

      assert_replacement " 	resources(:some_random, only: [:asd]) 	",
                         " 	resources(:some_random) 	"

      # 2. With block
      # 2.1 Without parentheses
      assert_replacement "resources :some_random, only: [:asd] do",
                         "resources :some_random do"

      assert_replacement " 	resources :some_random, only: [:asd] 	do 	",
                         " 	resources :some_random 	do 	"

      # 2.2 With parentheses
      assert_replacement "resources(:some_random, only: [:asd]) do",
                         "resources(:some_random) do"

      assert_replacement " 	resources(:some_random, only: [:asd]) 	do 	",
                         " 	resources(:some_random) 	do 	"

      # 3. With existing parameters
      # 3.1 With existing only:
      assert_replacement "resources :some, only: [:asd]",
                         "resources :some, only: [ :xxx, :yyy ]"

      # 3.2 With existing :only =>
      assert_replacement "resources :some, only: [:asd]",
                         "resources :some, :only => [ :xxx, :yyy ]"
      assert_replacement "resources :some, only: [:asd]",
                         "resources :some, :only=>[ :xxx, :yyy ]"

      # 3.3 With existing except:
      assert_replacement "resources :some, only: [:asd]",
                         "resources :some, except: [ :xxx, :yyy ]"

      # 3.4 With existing :except =>
      assert_replacement "resources :some, only: [:asd]",
                         "resources :some, :except => [ :xxx, :yyy ]"

      # 3.5 With existing unknown parameters
      assert_replacement "resources :some, random: [ asd ], :shallow => [ asd2, asd3 ], only: [:asd]",
                         "resources :some, random: [ asd ], :shallow => [ asd2, asd3 ]"

      # 3.6 With existing unknown parameters combined with only: before
      assert_replacement "resources :some, only: [:asd], random: [ asd ], :shallow => [ asd2, asd3 ]",
                         "resources :some, only: [ :asd, :xx], random: [ asd ], :shallow => [ asd2, asd3 ]"

      # 3.7 With existing unknown parameters combined with only: middle
      assert_replacement "resources :some, random: [ asd ], only: [:asd], :shallow => [ asd2, asd3 ]",
                         "resources :some, random: [ asd ], only: [ :asd, :xx], :shallow => [ asd2, asd3 ]"

      # 3.8 With existing unknown parameters combined with only: after
      assert_replacement "resources :some, random: [ asd ], only: [:asd], :shallow => [ asd2, asd3 ]",
                         "resources :some, random: [ asd ], only: [ :asd, :xx], :shallow => [ asd2, asd3 ]"

      # 3.9 With existing unknown parameters combined with :only => before
      assert_replacement "resources :some,  only: [:asd] , random: [ asd ], :shallow => [ asd2, asd3 ]",
                         "resources :some,  :only=>[ :asd, :xx] , random: [ asd ], :shallow => [ asd2, asd3 ]"

      # 3.10 With existing unknown parameters combined with :only => middle
      assert_replacement "resources :some,  random: [ asd ], key: \"as d\", only: [:asd],  :shallow => [ asd2, asd3 ]",
                         "resources :some,  random: [ asd ], key: \"as d\", :only=>[ :asd, :xx],  :shallow => [ asd2, asd3 ]"

      # 3.11 With existing unknown parameters combined with :only => after
      assert_replacement "resources :some,  random: [ asd ], :shallow => [ asd2, asd3 ], key: 'asd ',  only: [:asd]",
                         "resources :some,  random: [ asd ], :shallow => [ asd2, asd3 ], key: 'asd ',  :only=>[ :asd, :xx]"

      # 4. With parentheses
      assert_replacement "resources :some, { controller: [1, 2], only: [:asd] }",
                         "resources :some, { controller: [1, 2], only: [:xx, :yy ] }"

      assert_replacement "resources :some, { shallow: true, only: [:asd] }",
                         "resources :some, { shallow: true }"
    end

    def test_try_to_fix_resources_line_failure_cases
      # Unsupported parameter forms
      assert_replacement nil,
                         "resources :some, options"

    end

    def assert_replacement(result, original)
      actual = ResourcesRouteIssue.try_to_fix_resources_line("#{original}\n", "only: [:asd]")
      if result
        assert_equal "#{result}\n", actual
      else
        assert_nil actual
      end
    end
  end
end
