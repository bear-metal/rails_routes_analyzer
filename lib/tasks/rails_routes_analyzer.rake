namespace :routes do

  desc 'Scan for dead-end routes'
  task dead: :environment do
    analysis = RailsRoutesAnalyzer::RouteAnalysis.new(
                 RailsRoutesAnalyzer::ParameterHandler.params_for_route_analysis(ENV))

    analysis.print_report
  end

  namespace :dead do
    desc "Output a routes file with suggested modifications in comments (doesn't change the original file)"
    task annotate: :environment do
      annotator = RailsRoutesAnalyzer::RouteFileAnnotator.new(
                    RailsRoutesAnalyzer::ParameterHandler.params_for_annotate(ENV))

      annotator.annotate_routes_file(RailsRoutesAnalyzer::ParameterHandler.file_to_annotate(ENV))
    end

    desc "Outputs a routes file with simple fixes auto-applied others suggested in comments (doesn't change the original file)"
    task fix: :environment do
      annotator = RailsRoutesAnalyzer::RouteFileAnnotator.new(
                    RailsRoutesAnalyzer::ParameterHandler.params_for_fix(ENV))

      annotator.annotate_routes_file(RailsRoutesAnalyzer::ParameterHandler.file_to_annotate(ENV))
    end
  end

end

namespace :actions do

  desc 'List application actions which have no routes mapped to them'
  task missing_route: :environment do |_, args|
    params = RailsRoutesAnalyzer::ParameterHandler.params_for_action_analysis(
               ENV, args.extras).merge(report_routed: false)

    analysis = RailsRoutesAnalyzer::ActionAnalysis.new(params)
    analysis.print_report
  end

  desc 'List all actions provided by the application'
  task list_all: :environment do |_, args|
    params = RailsRoutesAnalyzer::ParameterHandler.params_for_action_analysis(
               ENV, args.extras).merge(report_routed: true)

    analysis = RailsRoutesAnalyzer::ActionAnalysis.new(params)
    analysis.print_report
  end

end
