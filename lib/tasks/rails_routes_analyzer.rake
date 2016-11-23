namespace :routes do

  desc 'Scan for dead-end routes including bad map.resource(s) :only/:except parameters'
  task dead: :environment do
    analysis = RailsRoutesAnalyzer::RouteAnalysis.new(
                 verbose:     !ENV['VERBOSE'].nil?,
                 only_only:   !ENV['ONLY_ONLY'].nil?,
                 only_except: !ENV['ONLY_EXCEPT'].nil?)

    if analysis.issues.empty?
      puts "No route issues found"
      exit 0
    end

    analysis.issues.each do |issue|
      puts issue.human_readable
    end
  end

  desc "Output a routes file with suggested modifications in comments (NOTE: doesn't touch the original file)"
  task annotate_dead: :environment do
    annotator = RailsRoutesAnalyzer::RouteFileAnnotator.new
    annotator.annotate_routes_file(ENV['ANNOTATE'])
  end

  desc 'Scan for controller action methods that are missing a route (pass STRICT=1 to account for inherited actions)'
  task missing: :environment do
    analysis = RailsRoutesAnalyzer::RouteAnalysis.new
    implemented_routes = analysis.implemented_routes
    all_action_methods = RailsRoutesAnalyzer.get_all_action_methods(ignore_parent_provided: ENV['STRICT'].blank?)

    missing = all_action_methods.to_a - implemented_routes.to_a

    if missing.any?
      puts "NOTE Some gems, such as Devise, are expected to provide actions that have no matching"
      puts "     routes in case a particular feature is not enabled, this is normal and expected."
      puts "NOTE If any non-action methods are reported please consider making those non-public"
      puts "     or using another solution that would make #action_methods not return those."
      puts ""

      unused_controllers = Set.new(all_action_methods.to_a.map(&:first) - implemented_routes.to_a.map(&:first))

      if unused_controllers.any?
        puts "Controllers with no routes pointing to them:"
        unused_controllers.to_a.sort.each do |controller_name|
          puts "  #{controller_name}"
        end
        puts ""
      end

      puts "Actions without a route:"
      missing.sort.each do |(controller_name, action_name)|
        unless unused_controllers.include?(controller_name)
          puts "  #{controller_name}::#{action_name}"
        end
      end
    else
      puts "There are no actions without a route"
    end
  end

end
