require "bundler/setup"

APP_RAKEFILE = File.expand_path("spec/dummy/Rakefile", __dir__)
load "rails/tasks/engine.rake"

load "rails/tasks/statistics.rake"

require "bundler/gem_tasks"

Dir.glob(File.expand_path("lib/tasks/**/*.rake", __dir__)).sort.each do |task_file|
  load task_file
end
