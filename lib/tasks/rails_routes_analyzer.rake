namespace :routes do
  desc 'Scan for dead-end routes'
  task dead: :environment do
    RailsRoutesAnalyzer.routes_dead(ENV)
  end

  namespace :dead do
    desc "Output a routes file with suggested modifications in comments (doesn't change the original file)"
    task annotate: :environment do
      RailsRoutesAnalyzer.routes_dead_annotate(ENV)
    end

    desc "Updates routes file(s) with suggestions for fixes in comments, requires unmodified git-controlled file(s)"
    task :"annotate:inplace" => :environment do |_, args|
      RailsRoutesAnalyzer.routes_dead_annotate_inplace(ENV, args.extras)
    end

    desc "Outputs a routes file with simple fixes auto-applied others suggested in comments (doesn't change the original file)"
    task fix: :environment do
      RailsRoutesAnalyzer.routes_dead_fix(ENV)
    end

    desc "Updates routes file(s) with simple fixes auto-applied others suggested in comments, requires unmodified git-controlled file(s)"
    task :"fix:inplace" => :environment do |_, args|
      RailsRoutesAnalyzer.routes_dead_fix_inplace(ENV, args.extras)
    end
  end
end

namespace :actions do
  desc 'List application actions which have no routes mapped to them'
  task missing_route: :environment do |_, args|
    RailsRoutesAnalyzer.routes_actions_missing_route(ENV, args.extras)
  end

  desc 'List all actions provided by the application'
  task list_all: :environment do |_, args|
    RailsRoutesAnalyzer.routes_actions_list_all(ENV, args.extras)
  end
end
