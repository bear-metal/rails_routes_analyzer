namespace :routes do

  desc 'Scan for dead-end routes including bad map.resource(s) :only/:except parameters'
  task dead: :environment do
    analysis = RailsRoutesAnalyzer::RouteAnalysis.new(
                 only_only:   !ENV['ONLY_ONLY'].nil?,
                 only_except: !ENV['ONLY_EXCEPT'].nil?)

    if analysis.issues.empty?
      puts "No route issues found"
      exit 0
    end

    verbose = !ENV['ROUTES_VERBOSE'].nil?

    analysis.issues.each do |issue|
      puts issue.human_readable_error(verbose: verbose)
    end
  end

  desc "Output a routes file with suggested modifications in comments (NOTE: doesn't touch the original file)"
  task annotate_dead: :environment do
    annotator = RailsRoutesAnalyzer::RouteFileAnnotator.new(
                  try_to_fix:     ENV['ROUTES_TRY_TO_FIX'] == 'experimental',
                  allow_deleting: ENV['ROUTES_ALLOW_DELETING'].present?,
                )
    annotator.annotate_routes_file(ENV['ROUTES_ANNOTATE'])
  end

  desc 'Scan for controller action methods that are missing a route'
  task missing: :environment do
    report_all = ENV['ROUTES_ALL'].present?
    analysis = RailsRoutesAnalyzer::ActionAnalysis.new(show_duplicates: ENV['ROUTES_DUPLICATES'].present?,
                                                       ignore_gems:     ENV['ROUTES_GEMS'].blank?,
                                                       full_path:       ENV['ROUTES_FULL_PATH'].present?,
                                                       report_modules:  ENV['ROUTES_MODULES'].present?,
                                                       metadata:        ENV['ROUTES_METADATA'].present?,
                                                       report_all: report_all)

    unless report_all
      if analysis.unused_controllers.present?
        puts "Controllers with no routes pointing to them:"
        analysis.unused_controllers.sort_by(&:name).each do |controller|
          puts "  #{controller.name}"
        end
        puts
      end

      unless analysis.unused_actions_present?
        puts "There are no actions without a route"
        exit 0
      end

      puts "NOTE Some gems, such as Devise, are expected to provide actions that have no matching"
      puts "     routes in case a particular feature is not enabled, this is normal and expected."
      puts "NOTE If any non-action methods are reported please consider making those non-public"
      puts "     or using another solution that would make #action_methods not return those."
      puts ""
      puts "Actions without a route:"
      puts ""
    end

    analysis.report_actions
  end

end
