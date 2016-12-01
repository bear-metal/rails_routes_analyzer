require 'test_helper'

module RailsRoutesAnalyzer
  class ResourcesRouteIssueTest < TestCase
    def test_resources_action_limit_suggestion
      issue = get_issue_at 'routes_bad.rb:4'
      assert_equal "`resources' call at routes_bad.rb:4 for HomeController should use only: [:index, :show]", issue.human_readable_error
      assert_equal 4, issue.line_number
      assert_equal File.expand_path('../../dummy/routes_bad.rb', __FILE__), issue.full_filename
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
