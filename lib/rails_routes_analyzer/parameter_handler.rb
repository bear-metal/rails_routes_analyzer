module RailsRoutesAnalyzer
  module ParameterHandler
    def self.params_for_route_analysis(env = ENV)
      {
        only_only:   env['ONLY_ONLY'].present?,
        only_except: env['ONLY_EXCEPT'].present?,
        verbose:     env['ROUTES_VERBOSE'].present?,
      }
    end

    def self.params_for_annotate(env = ENV)
      params_for_route_analysis.merge(
        try_to_fix:     false,
        allow_deleting: false,
        force_overwrite: env['ROUTES_FORCE'].present?,
      )
    end

    def self.file_to_annotate(env = ENV)
      env['ROUTES_FILE']
    end

    def self.params_for_fix(env = ENV)
      params_for_route_analysis.merge(
        try_to_fix:     true,
        allow_deleting: true,
        force_overwrite: env['ROUTES_FORCE'].present?,
      )
    end

    def self.params_for_action_analysis(env = ENV, extras=[])
      {
        report_duplicates: env['ROUTES_DUPLICATES'].present? || extras.include?('duplicates'),
        report_gems:       env['ROUTES_GEMS'].present?       || extras.include?('gems'),
        report_modules:    env['ROUTES_MODULES'].present?    || extras.include?('modules'),
        full_path:         env['ROUTES_FULL_PATH'].present?  || extras.include?('full'),
        metadata:          env['ROUTES_METADATA'].present?   || extras.include?('metadata'),
      }
    end
  end
end
