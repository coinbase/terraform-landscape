require_relative './spec_helper'
require 'terraform_landscape/output'
require 'terraform_landscape/printer'

describe TerraformLandscape::Printer do
  let(:output_io) do
    StringIO.new
  end
  let(:printer) do
    output = TerraformLandscape::Output.new(output_io)
    TerraformLandscape::Printer.new(output)
  end

  before(:all) do
    String.disable_colorization = true
  end

  after(:all) do
    String.disable_colorization = false
  end

  describe '#process_string' do
    subject do
      printer.process_string(terraform_output)
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

    context 'when output contains initialization messages' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        Initializing provider plugins...
        - Checking for available provider plugins on https://releases.hashicorp.com...
        - Downloading plugin for provider "aws" (1.1.0)...

        The following providers do not have any version constraints in configuration,
        so the latest version was installed.

        To prevent automatic upgrades to new major versions that may contain breaking
        changes, it is recommended to add version = "..." constraints to the
        corresponding provider blocks in configuration, with the constraint strings
        suggested below.

        * provider.aws: version = "~> 1.1"

        Terraform has been successfully initialized!

        You may now begin working with Terraform. Try running "terraform plan" to see
        any changes that are required for your infrastructure. All Terraform commands
        should now work.

        If you ever set or change modules or backend configuration for Terraform,
        rerun this command to reinitialize your working directory. If you forget, other
        commands will detect it and remind you to do so if necessary.

        No changes. Infrastructure is up-to-date.

        This means that Terraform did not detect any differences between your
        configuration and real physical resources that exist. As a result, no
        actions need to be performed.
      TXT

      it { should == normalize_indent(<<-OUT) }
        No changes
      OUT
    end

    context 'when output contains a separator after refreshing state' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        Refreshing Terraform state in-memory prior to plan...
        The refreshed state will be used to calculate this plan, but will not be
        persisted to local or remote state storage.

        aws_vpc.poc: Refreshing state... (ID:   ##vpc-xxxxxxxxxxxxx)
        data.aws_iam_policy_document.flowlogs: Refreshing state...
        data.aws_iam_policy_document.rds_assume_policy: Refreshing state...
        data.aws_iam_policy_document.flowlogs_assume_role_policy: Refreshing state...
        aws_iam_role.rds: Refreshing state... (ID: xxxxxxxxxxxxxxxxxRole)
        aws_iam_role.flowlogs: Refreshing state... (ID: xxxxxxxxxxxxxxRole)
        aws_iam_role_policy.flowlogs: Refreshing state... (ID: xxxxxxxxxxxxxCreatePolicy)
        aws_iam_role_policy_attachment.rds: Refreshing state... (ID: xxxxxxxxxxxxxxRole-20171030050803915500000001)

        ------------------------------------------------------------------------

        No changes. Infrastructure is up-to-date.

        This means that Terraform did not detect any differences between your
        configuration and real physical resources that exist. As a result, no
        actions need to be performed.
      TXT

      it { should == normalize_indent(<<-OUT) }
        No changes
      OUT
    end
  end

  describe '#process_stream' do
    subject do
      output_io.string
    end

    around(:each) do |example|
      Timeout.timeout(2) do
        example.run
      end
    end

    it 'processes a completed stream' do
      terraform_output = normalize_indent(<<-TXT)
      Path: terraform.tfplan

        ~ some_resource_type.some_resource_name
            some_attribute_name:    "3" => "4"

      Plan: 0 to add, 1 to change, 0 to destroy.
      Releasing state lock. This may take a few moments...
      TXT

      outstream, instream = IO.pipe
      terraform_output.split("\n").each do |line|
        instream.puts(line)
      end
      instream.close
      printer.process_stream(outstream)

      should == normalize_indent(<<-OUT)
      ~ some_resource_type.some_resource_name
          some_attribute_name:   "3" => "4"

      Plan: 0 to add, 1 to change, 0 to destroy.

      OUT
    end

    it "processes an apply prompt that's still open" do
      terraform_output = normalize_indent(<<-TXT)
      Path: terraform.tfplan

        ~ some_resource_type.some_resource_name
            some_attribute_name:    "3" => "4"

      Plan: 0 to add, 1 to change, 0 to destroy.

      Do you want to perform these actions?
        Terraform will perform the actions described above.
        Only 'yes' will be accepted to approve.

        Enter a value:
      TXT

      begin
        outstream, instream = IO.pipe

        process = Thread.new do
          printer.process_stream(outstream)
        end

        terraform_output.split("\n").each do |line|
          instream.puts(line)
        end

        sleep(0.2)

        should == normalize_indent(<<-OUT)
        ~ some_resource_type.some_resource_name
            some_attribute_name:   "3" => "4"

        Plan: 0 to add, 1 to change, 0 to destroy.

        Do you want to perform these actions?
          Terraform will perform the actions described above.
          Only 'yes' will be accepted to approve.

          Enter a value:
        OUT
      ensure
        # finish off the input stream and check that the process ends
        instream.close
        process.join
      end
    end

    it 'falls back on the original Terraform output when a ParseError occurs' do
      terraform_output = 'gibberishhsirebbiggibberish'
      outstream, instream = IO.pipe
      terraform_output.split("\n").each do |line|
        instream.puts(line)
      end
      instream.close
      printer.process_stream(outstream)
      should == TerraformLandscape::FALLBACK_MESSAGE + "\n" + terraform_output + "\n"
    end

    it 'returns stack trace when a ParseError occurs and the trace option is provided' do
      terraform_output = 'gibberishhsirebbiggibberish'
      outstream, instream = IO.pipe
      terraform_output.split("\n").each do |line|
        instream.puts(line)
      end
      instream.close
      expect { printer.process_stream(outstream, { trace: true }) }.to raise_error(TerraformLandscape::ParseError)
    end
  end
end
