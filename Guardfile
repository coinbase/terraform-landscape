rspec_options = {
  cmd: "bundle exec rspec",
  all_on_start: true
}

guard :rspec, **rspec_options do
  require "guard/rspec/dsl"
  dsl = Guard::RSpec::Dsl.new(self)

  # RSpec files
  rspec = dsl.rspec
  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(rspec.spec_support) { rspec.spec_dir }
  watch(rspec.spec_files) { rspec.spec_dir }

  # Ruby files
  ruby = dsl.ruby
  watch(ruby.lib_files) { rspec.spec_dir }

  notification :gntp
end
