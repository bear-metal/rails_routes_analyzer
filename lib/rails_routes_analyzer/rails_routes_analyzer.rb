require_relative 'gem_manager'

module RailsRoutesAnalyzer

  MULTI_METHODS = %w(resource resources).freeze
  SINGLE_METHODS = %w(match get head post patch put delete options root).freeze
  ROUTE_METHODS = (MULTI_METHODS + SINGLE_METHODS).freeze

  class << self
    # Converts Rails.root-relative filenames to be absolute.
    def get_full_filename(filename)
      return filename.to_s if filename.to_s.starts_with?('/')
      Rails.root.join(filename).to_s
    end

    # Shortens full file path, replacing Rails.root and gem path with
    # appropriate short prefixes to make the file names look good.
    def sanitize_source_location(source_location, full_path: false)
      source_location.dup.tap do |clean_location|
        unless full_path
          clean_location.gsub! "#{Rails.root}/", './'

          clean_location.replace GemManager.clean_gem_path(clean_location)
        end
      end
    end

    def routes_dead(env)
      params   = RailsRoutesAnalyzer::ParameterHandler.params_for_route_analysis(env)
      analysis = RailsRoutesAnalyzer::RouteAnalysis.new(params)

      analysis.print_report
    end

    def routes_dead_annotate(env)
      routes_dead_annotate_common(env)
    end

    def routes_dead_annotate_inplace(env, extras)
      routes_dead_annotate_common(env, extras, inplace: true)
    end

    def routes_dead_fix(env)
      routes_dead_fix_common(env)
    end

    def routes_dead_fix_inplace(env, extras)
      routes_dead_fix_common(env, extras, inplace: true)
    end

    def routes_actions_missing_route(env, extras)
      routes_actions_common(env, extras, report_routed: false)
    end

    def routes_actions_list_all(env, extras)
      routes_actions_common(env, extras, report_routed: true)
    end

    protected

    def routes_dead_annotate_common(env, extras = [], **opts)
      params      = RailsRoutesAnalyzer::ParameterHandler.params_for_annotate(env, extras)
      annotator   = RailsRoutesAnalyzer::RouteFileAnnotator.new(params)
      routes_file = RailsRoutesAnalyzer::ParameterHandler.file_to_annotate(env)

      annotator.annotate_routes_file(routes_file, **opts)
    end

    def routes_dead_fix_common(env, extras = [], **opts)
      params    = RailsRoutesAnalyzer::ParameterHandler.params_for_fix(env, extras)
      annotator = RailsRoutesAnalyzer::RouteFileAnnotator.new(params)
      routes_file = RailsRoutesAnalyzer::ParameterHandler.file_to_annotate(env)

      annotator.annotate_routes_file(routes_file, **opts)
    end

    def routes_actions_common(env, extras, **opts)
      params = RailsRoutesAnalyzer::ParameterHandler.params_for_action_analysis(env, extras)
      analysis = RailsRoutesAnalyzer::ActionAnalysis.new(params.merge(opts))
      analysis.print_report
    end
  end

end
