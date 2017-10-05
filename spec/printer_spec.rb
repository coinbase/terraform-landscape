require_relative './spec_helper'
require 'terraform_landscape/output'
require 'terraform_landscape/printer'

describe TerraformLandscape::Printer do
  describe '#display' do
    before(:all) do
      String.disable_colorization = true
    end

    after(:all) do
      String.disable_colorization = false
    end

    subject do
      output_io = StringIO.new
      output = TerraformLandscape::Output.new(output_io)
      TerraformLandscape::Printer.new(output).process_string(terraform_output)
      output_io.string
    end

    context 'when there are no changes' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        Acquiring state lock. This may take a few moments...
        Refreshing Terraform state in-memory prior to plan...
        The refreshed state will be used to calculate this plan, but will not be
        persisted to local or remote state storage.

        aws_iam_role.role: Refreshing state... (ID: role)
        No changes. Infrastructure is up-to-date.

        This means that Terraform did not detect any differences between your
        configuration and real physical resources that exist. As a result, Terraform
        doesn't need to do anything.
        Releasing state lock. This may take a few moments...
      TXT

      it { should == normalize_indent(<<-OUT) }
        No changes
      OUT
    end

    context 'when plan does nothing' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        Acquiring state lock. This may take a few moments...
        Refreshing Terraform state in-memory prior to plan...
        The refreshed state will be used to calculate this plan, but will not be
        persisted to local or remote state storage.

        aws_iam_role.role: Refreshing state... (ID: role)
        This plan does nothing.

        This means that Terraform did not detect any differences between your
        configuration and real physical resources that exist. As a result, Terraform
        doesn't need to do anything.
        Releasing state lock. This may take a few moments...
      TXT

      it { should == normalize_indent(<<-OUT) }
        No changes
      OUT
    end

    context 'when output contains a pre- and post-face' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
      Path: terraform.tfplan

        ~ some_resource_type.some_resource_name
            some_attribute_name:    "3" => "4"

      Plan: 0 to add, 1 to change, 0 to destroy.
      Releasing state lock. This may take a few moments...
      TXT

      it { should == normalize_indent(<<-OUT) }
      ~ some_resource_type.some_resource_name
          some_attribute_name:   "3" => "4"

      Plan: 0 to add, 1 to change, 0 to destroy.

      OUT
    end

    context 'when output contains a legend of the resource operations' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
      Resource actions are indicated with the following symbols:
        + create
        ~ update in-place

      Terraform will perform the following actions:

        ~ some_resource_type.some_resource_name
            some_attribute_name:    "3" => "4"

      Plan: 0 to add, 1 to change, 0 to destroy.
      Releasing state lock. This may take a few moments...
      TXT

      it { should == normalize_indent(<<-OUT) }
      ~ some_resource_type.some_resource_name
          some_attribute_name:   "3" => "4"

      Plan: 0 to add, 1 to change, 0 to destroy.

      OUT
    end

    context 'when output does not contain a Path' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
      Note: You didn't specify an "-out" parameter to save this plan, so when
      "apply" is called, Terraform can't guarantee this is what will execute.

        ~ some_resource_type.some_resource_name
            some_attribute_name:    "3" => "4"

      Plan: 0 to add, 1 to change, 0 to destroy.
      Releasing state lock. This may take a few moments...
      TXT

      it { should == normalize_indent(<<-OUT) }
      ~ some_resource_type.some_resource_name
          some_attribute_name:   "3" => "4"

      Plan: 0 to add, 1 to change, 0 to destroy.

      OUT
    end

    context 'when output does not contain a pre- or post-face' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        ~ some_resource_type.some_resource_name
            some_attribute_name:    "3" => "4"
      TXT

      it { should == normalize_indent(<<-OUT) }
        ~ some_resource_type.some_resource_name
            some_attribute_name:   "3" => "4"


      OUT
    end
  end
end
