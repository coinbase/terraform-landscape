# frozen_string_literal: true

# Global application constants.
module TerraformLandscape
  HOME = File.expand_path(File.join(File.dirname(__FILE__), '..', '..')).freeze

  REPO_URL = 'https://github.com/coinbase/terraform_landscape'.freeze
  BUG_REPORT_URL = "#{REPO_URL}/issues".freeze

  FALLBACK_MESSAGE = 'Terraform Landscape: a parsing error occured. Falling back to original Terraform output...'
end