require_relative "lib/haya_select_helpers/version"

Gem::Specification.new do |spec|
  spec.name        = "haya_select_helpers"
  spec.version     = HayaSelectHelpers::VERSION
  spec.authors     = ["kaspernj"]
  spec.email       = ["kasper@diestoeckels.de"]
  spec.homepage    = "https://github.com/kaspernj/haya_select_helpers"
  spec.summary     = "RSpec helpers for HayaSelect."
  spec.description = "RSpec helpers for HayaSelect."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kaspernj/haya_select_helpers"
  spec.metadata["changelog_uri"] = "https://github.com/kaspernj/haya_select_helpers"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.3"
end
