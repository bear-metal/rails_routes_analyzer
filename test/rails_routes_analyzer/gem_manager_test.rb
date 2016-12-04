require 'test_helper'

module RailsRoutesAnalyzer
  class GemManagerTest < TestCase

    def test_clean_gem_path
      gem_path = Gem.loaded_specs['minitest'].full_gem_path
      file_path = 'lib/some/path.rb'
      full_path = File.join(gem_path, file_path)

      assert_equal "minitest @ #{file_path}", GemManager.clean_gem_path(full_path)
    end

    def test_identify_gem
      gem_path = Gem.loaded_specs['minitest'].full_gem_path
      file_path = 'lib/some/path.rb'
      full_path = File.join(gem_path, file_path)

      assert_equal "minitest", GemManager.identify_gem(full_path)
    end

  end
end
