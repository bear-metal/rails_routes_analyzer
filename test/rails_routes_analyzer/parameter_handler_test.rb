require 'test_helper'

module RailsRoutesAnalyzer
  class ParameterHandlerTest < Minitest::Test

    def test_params_for_route_analysis
      expected = { only_only: false, only_except: false, verbose: false }
      assert_equal expected, ParameterHandler.params_for_route_analysis({})

      env = { 'ONLY_ONLY' => '1', 'ONLY_EXCEPT' => '1', 'ROUTES_VERBOSE' => '1' }
      expected = { only_only: true, only_except: true, verbose: true }
      assert_equal expected, ParameterHandler.params_for_route_analysis(env)
    end

    def test_params_for_annotate
      expected = { only_only: false, only_except: false, verbose: false, try_to_fix: false, allow_deleting: false, force_overwrite: false }
      assert_equal expected, ParameterHandler.params_for_annotate({})

      env = { 'ROUTES_FORCE' => '1' }
      expected = expected.merge(force_overwrite: true)
      assert_equal expected, ParameterHandler.params_for_annotate(env)
    end

    def test_file_to_annotate
      assert_nil ParameterHandler.file_to_annotate({})

      assert_equal 'asd', ParameterHandler.file_to_annotate('ROUTES_FILE' => 'asd')
    end

    def test_params_for_fix
      expected = { only_only: false, only_except: false, verbose: false, try_to_fix: true, allow_deleting: true, force_overwrite: false }
      assert_equal expected, ParameterHandler.params_for_fix({})

      env = { 'ROUTES_FORCE' => '1' }
      expected = expected.merge(force_overwrite: true)
      assert_equal expected, ParameterHandler.params_for_fix(env)
    end

    def test_params_for_action_analysis
      expected = { report_duplicates: false, report_gems: false, report_modules: false, full_path: false, metadata: false }
      assert_equal expected, ParameterHandler.params_for_action_analysis({})

      env = {
        'ROUTES_DUPLICATES' => '1',
        'ROUTES_GEMS'       => '1',
        'ROUTES_MODULES'    => '1',
        'ROUTES_FULL_PATH'  => '1',
        'ROUTES_METADATA'   => '1',
      }
      expected = { report_duplicates: true, report_gems: true, report_modules: true, full_path: true, metadata: true }

      assert_equal expected, ParameterHandler.params_for_action_analysis(env)

      extras = %w(duplicates gems modules full metadata)
      assert_equal expected, ParameterHandler.params_for_action_analysis({}, extras)
    end

  end
end
