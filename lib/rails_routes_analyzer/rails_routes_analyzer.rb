require_relative 'gem_manager'

module RailsRoutesAnalyzer

  MULTI_METHODS = %w(resource resources).freeze
  SINGLE_METHODS = %w(match get head post patch put delete options root).freeze
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

        clean_location.replace GemManager.clean_gem_path(clean_location)
      end
    end
  end

end
