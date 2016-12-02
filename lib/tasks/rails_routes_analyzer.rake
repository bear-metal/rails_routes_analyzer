namespace :routes do

  desc 'Scan for dead-end routes'
  task dead: :environment do
    analysis = RailsRoutesAnalyzer::RouteAnalysis.new(
                 only_only:   !ENV['ONLY_ONLY'].nil?,
                 only_except: !ENV['ONLY_EXCEPT'].nil?,
                 verbose:     ENV['ROUTES_VERBOSE'])

    analysis.print_report
  end

  desc "Output a routes file with suggested modifications in comments (doesn't change the original file)"
  task annotate_dead: :environment do
    annotator = RailsRoutesAnalyzer::RouteFileAnnotator.new(
                  try_to_fix:     ENV['ROUTES_TRY_TO_FIX'] == 'experimental',
                  allow_deleting: ENV['ROUTES_ALLOW_DELETING'].present?)

    annotator.annotate_routes_file(ENV['ROUTES_ANNOTATE'])
  end

  desc 'Scan for controller action methods that are missing a route'
  task missing: :environment do
    analysis = RailsRoutesAnalyzer::ActionAnalysis.new(
                 show_duplicates: ENV['ROUTES_DUPLICATES'].present?,
                 ignore_gems:     ENV['ROUTES_GEMS'].blank?,
                 full_path:       ENV['ROUTES_FULL_PATH'].present?,
                 report_modules:  ENV['ROUTES_MODULES'].present?,
                 metadata:        ENV['ROUTES_METADATA'].present?,
                 report_all:      ENV['ROUTES_ALL'].present?)

    analysis.print_report
  end

end
