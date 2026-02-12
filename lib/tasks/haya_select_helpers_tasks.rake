namespace :release do
  desc "Bump patch version and release gem"
  task patch: :environment do
    version_file = File.expand_path("../haya_select_helpers/version.rb", __dir__)
    current_version = File.read(version_file).match(/VERSION\s*=\s*"(\d+\.\d+\.\d+)"/)&.captures&.first
    abort("Could not read current version from #{version_file}") unless current_version

    segments = current_version.split(".").map(&:to_i)
    segments[2] += 1
    new_version = segments.join(".")

    updated = File.read(version_file).sub(/VERSION\s*=\s*"\d+\.\d+\.\d+"/, %(VERSION = "#{new_version}"))
    File.write(version_file, updated)
    puts "Version bumped: #{current_version} -> #{new_version}"

    run_command("bundle install")
    run_command("git add lib/haya_select_helpers/version.rb Gemfile.lock")
    run_command(%(git commit -m "Release #{new_version}"))
    current_branch = `git branch --show-current`.strip
    run_command("git push --set-upstream origin #{current_branch}")

    gem_file = "haya_select_helpers-#{new_version}.gem"
    run_command("gem build haya_select_helpers.gemspec")
    run_command("gem push #{gem_file}")
  end

  def run_command(command)
    puts "Running: #{command}"
    success = system(command)
    abort("Command failed: #{command}") unless success
  end
end
