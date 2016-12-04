# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails_routes_analyzer/version'

Gem::Specification.new do |spec|
  spec.name          = "rails_routes_analyzer"
  spec.version       = RailsRoutesAnalyzer::VERSION
  spec.authors       = ["Bear Metal OÜ", "Tarmo Tänav"]
  spec.email         = ["tarmo@bearmetal.eu"]
  spec.required_ruby_version = ">= 2.1.0"

  spec.summary       = %q{Helps clean up rails routes}
  #spec.description   = %q{}
  spec.homepage      = "https://github.com/bear-metal/rails_routes_analyzer"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "actionpack", ">= 3.2"
  spec.add_runtime_dependency "git"

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.10.1"
  spec.add_development_dependency "minitest-reporters", "~> 1.1.12"
  spec.add_development_dependency "minitest-color", "~> 0.0.2"
  spec.add_development_dependency "minitest-focus"
  spec.add_development_dependency "minitest-autotest"
  spec.add_development_dependency "autotest-suffix"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "simplecov"
end
