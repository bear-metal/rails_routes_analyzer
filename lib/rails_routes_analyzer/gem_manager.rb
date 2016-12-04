module RailsRoutesAnalyzer
  module GemManager
    extend self

    # Replaces gem locations in file paths with the name of the gem.
    #
    # @param location [String] full path to a ruby source file.
    # @return [String] path to ruby source file with gem location replaced.
    def clean_gem_path(location)
      location.gsub(gem_path_prefix_cleanup_regex) do |val|
        gem_path_prefix_replacements[val] || val
      end
    end

    # Identifies a gem based on a location from a backtrace.
    #
    # @param location [String] full path to a source file possibly in a gem.
    # @return [String] name of a gem.
    def identify_gem(location)
      gem_locations[location[gem_locations_regexp]]
    end

    private

    # @return { String => String } mapping of gem path prefix to gem name.
    def gem_path_prefix_replacements
      @gem_path_prefix_replacements ||=
        Gem.loaded_specs.values.each_with_object({}) do |spec, sum|
          path = spec.full_gem_path.sub %r{/?\z}, '/'
          sum[path] = "#{spec.name} @ "
        end
    end

    # @return [Regexp] a regexp that matches all gem paths.
    def gem_path_prefix_cleanup_regex
      @gem_path_prefix_cleanup_regex ||=
        /\A#{Regexp.union(gem_path_prefix_replacements.keys)}/
    end

    # @return {String=>String} mapping of gem path to gem name.
    def gem_locations
      @gem_locations ||= Gem.loaded_specs.values.each_with_object({}) do |spec, sum|
        sum[spec.full_gem_path] = spec.name
      end
    end

    # @return [Regexp] a regexp covering paths of all available gems.
    def gem_locations_regexp
      @gem_locations_regexp ||= /\A#{Regexp.union(gem_locations.keys)}/
    end
  end
end
