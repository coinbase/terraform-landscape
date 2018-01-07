$LOAD_PATH << File.expand_path('../lib', __FILE__)
require 'terraform_landscape/constants'
require 'terraform_landscape/version'

Gem::Specification.new do |s|
  s.name                  = 'terraform_landscape'
  s.version               = TerraformLandscape::VERSION
  s.license               = 'Apache-2.0'
  s.summary               = 'Pretty-print Terraform plan output'
  s.description           = 'Improve output of Terraform plans with color and indentation'
  s.authors               = ['Coinbase', 'Shane da Silva']
  s.email                 = ['shane@coinbase.com']
  s.homepage              = TerraformLandscape::REPO_URL

  s.require_paths         = %w[lib]

  s.executables           = ['landscape']

  s.files                 = Dir['bin/**/*'] +
                            Dir['lib/**/*.rb'] +
                            Dir['grammar/**/*.treetop']

  s.required_ruby_version = '>= 2'

  s.add_dependency 'colorize',    '~> 0.7'
  s.add_dependency 'commander',   '~> 4.4'
  s.add_dependency 'diffy',       '~> 3.0'
  s.add_dependency 'neatjson',    '~> 0.8'
  s.add_dependency 'treetop',     '~> 1.6'
end
