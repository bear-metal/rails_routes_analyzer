module RailsRoutesAnalyzer

  MULTI_METHODS = %w[resource resources].freeze
  SINGLE_METHODS = %w[match get head post patch put delete options root].freeze
  ROUTE_METHODS = (MULTI_METHODS + SINGLE_METHODS).freeze

  # Converts Rails.root-relative filenames to be absolute.
  def self.get_full_filename(filename)
    return filename.to_s if filename.to_s.starts_with?('/')
    Rails.root.join(filename).to_s
  end

  # Shortens full file path, replacing Rails.root and gem path with
  # appropriate short prefixes to make the file names look good.
  def self.sanitize_source_location(source_location, full_path: false)
    source_location.dup.tap do |clean_location|
      unless full_path
        clean_location.gsub! "#{Rails.root}/", './'

        clean_location.gsub! @cleanup_regexp do |val|
          gem_path_prefix_replacements[val] || val
        end
      end
    end
  end

  # @return { String => String } mapping of gem path prefix to gem name.
  def self.gem_path_prefix_replacements
    @gem_path_prefix_replacements ||=
      Gem.loaded_specs.values.each_with_object({}) do |spec, sum|
        path = spec.full_gem_path.sub /\/?\z/, '/'
        sum[path] = "#{spec.name} @ "
      end
  end

  # @return [Regexp] a regexp that matches all gem paths.
  def self.gem_path_prefix_cleanup_regex
    @gem_path_prefix_cleanup_regex ||=
      /\A#{Regexp.union(gem_path_prefix_replacements.keys)}/
  end

end
