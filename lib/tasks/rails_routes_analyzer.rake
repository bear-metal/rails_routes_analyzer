namespace :routes do
  desc 'Scan for dead-end routes'
  task dead: :environment do
    params   = RailsRoutesAnalyzer::ParameterHandler.params_for_route_analysis(ENV)
    analysis = RailsRoutesAnalyzer::RouteAnalysis.new(params)

    analysis.print_report
  end

  namespace :dead do
    desc "Output a routes file with suggested modifications in comments (doesn't change the original file)"
    task annotate: :environment do
      params    = RailsRoutesAnalyzer::ParameterHandler.params_for_annotate(ENV)
      annotator = RailsRoutesAnalyzer::RouteFileAnnotator.new(params)

      annotator.annotate_routes_file(RailsRoutesAnalyzer::ParameterHandler.file_to_annotate(ENV))
    end

    desc "Updates routes file(s) with suggestions for fixes in comments, requires unmodified git-controlled file(s)"
    task :"annotate:inplace" => :environment do
      params      = RailsRoutesAnalyzer::ParameterHandler.params_for_annotate(ENV)
      annotator   = RailsRoutesAnalyzer::RouteFileAnnotator.new(params)
      routes_file = RailsRoutesAnalyzer::ParameterHandler.file_to_annotate(ENV)

      annotator.annotate_routes_file(routes_file, inplace: true)
    end

    desc "Outputs a routes file with simple fixes auto-applied others suggested in comments (doesn't change the original file)"
    task fix: :environment do
      params    = RailsRoutesAnalyzer::ParameterHandler.params_for_fix(ENV)
      annotator = RailsRoutesAnalyzer::RouteFileAnnotator.new(params)

      annotator.annotate_routes_file(RailsRoutesAnalyzer::ParameterHandler.file_to_annotate(ENV))
    end

    desc "Updates routes file(s) with simple fixes auto-applied others suggested in comments, requires unmodified git-controlled file(s)"
    task :"fix:inplace" => :environment do
      params      = RailsRoutesAnalyzer::ParameterHandler.params_for_fix(ENV)
      annotator   = RailsRoutesAnalyzer::RouteFileAnnotator.new(params)
      routes_file = RailsRoutesAnalyzer::ParameterHandler.file_to_annotate(ENV)

      annotator.annotate_routes_file(routes_file, inplace: true)
    end
  end
end

namespace :actions do
  desc 'List application actions which have no routes mapped to them'
  task missing_route: :environment do |_, args|
    params = RailsRoutesAnalyzer::ParameterHandler.params_for_action_analysis(ENV, args.extras)
    params[:report_routed] = false

    analysis = RailsRoutesAnalyzer::ActionAnalysis.new(params)
    analysis.print_report
  end

  desc 'List all actions provided by the application'
  task list_all: :environment do |_, args|
    params = RailsRoutesAnalyzer::ParameterHandler.params_for_action_analysis(ENV, args.extras)
    params[:report_routed] = true

    analysis = RailsRoutesAnalyzer::ActionAnalysis.new(params)
    analysis.print_report
  end
end
