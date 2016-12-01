module RailsRoutesAnalyzer

  MULTI_METHODS = %w[resource resources].freeze
  SINGLE_METHODS = %w[match get head post patch put delete options root].freeze
  ROUTE_METHODS = (MULTI_METHODS + SINGLE_METHODS).freeze

  def self.get_full_filename(filename)
    return filename.to_s if filename.to_s.starts_with?('/')
    Rails.root.join(filename).to_s
  end

  RESOURCE_ACTIONS = [:index, :create, :new, :show, :update, :destroy, :edit]

  def self.identify_route_issues
    RouteAnalysis.new
  end

  def self.get_all_defined_routes
    identify_route_issues[:implemented_routes]
  end

  def self.sanitize_source_location(source_location, full_path: false)
    unless full_path
      @replacements ||= Gem.loaded_specs.values.each_with_object({}) do |spec, sum|
        path = spec.full_gem_path.sub /\/?\z/, '/'
        sum[path] = "#{spec.name} @ "
      end

      @cleanup_regexp ||= /\A#{Regexp.union(@replacements.keys)}/
    end

    source_location.dup.tap do |clean_location|
      unless full_path
        clean_location.gsub! "#{Rails.root}/", './'

        clean_location.gsub! @cleanup_regexp do |val|
          @replacements[val] || val
        end
      end
    end
  end

end
