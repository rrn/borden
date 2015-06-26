$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "borden_system/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "borden_system"
  s.version     = BordenSystem::VERSION
  s.authors     = ["Nicholas Jakobsen", "Ryan Wallace"]
  s.email       = ["contact@culturecode.ca"]
  s.homepage    = "https://github.com/rrn/borden"
  s.summary     = "Helper methods for manipulating border numbers"
  s.description = "Helper methods for manipulating border numbers"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_development_dependency 'rspec'
end
