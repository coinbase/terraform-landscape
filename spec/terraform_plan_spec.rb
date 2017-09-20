require_relative './spec_helper'
require 'terraform_landscape/terraform_plan'

describe TerraformLandscape::TerraformPlan do
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
      described_class.from_output(terraform_output).display(output)
      output_io.string
    end

    context 'when there is no output' do
      let(:terraform_output) { '' }
      it { should be_empty }
    end

    context 'when output contains only whitespace' do
      let(:terraform_output) { "  \n  " }
      it { should be_empty }
    end

    context 'when output contains a single resource with one attribute' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        ~ some_resource_type.some_resource_name
            some_attribute_name:    "3" => "4"
      TXT

      it { should == normalize_indent(<<-OUT) }
        ~ some_resource_type.some_resource_name
            some_attribute_name:   "3" => "4"

      OUT
    end

    context 'when output contains a resource with an index number' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        + some_resource_type.some_resource_name.0

      TXT

      it { should == normalize_indent(<<-OUT) }
        + some_resource_type.some_resource_name.0

      OUT
    end

    context 'when output contains a single resource with no attributes' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        - some_resource_type.some_resource_name

      TXT

      it { should == normalize_indent(<<-OUT) }
        - some_resource_type.some_resource_name

      OUT
    end

    context 'when output contains a multiple resources with no attributes' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        + some_resource_type.some_resource_name

        + some_resource_type.some_resource_name

      TXT

      it { should == normalize_indent(<<-OUT) }
        + some_resource_type.some_resource_name

        + some_resource_type.some_resource_name

      OUT
    end

    context 'when output contains resources separate by Windows newlines' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        + some_resource_type.some_resource_name\r\n
        + some_resource_type.some_resource_name\r\n
      TXT

      it { should == normalize_indent(<<-OUT) }
        + some_resource_type.some_resource_name

        + some_resource_type.some_resource_name

      OUT
    end

    context 'when output contains a single resource with multiple attributes' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        ~ some_resource_type.some_resource_name
            some_attribute_name:         "3" => "4"
            another_attribute_name:      "6" => "7"
            yet_another_attribute_name:  "9" => "7"
      TXT

      it { should == normalize_indent(<<-OUT) }
        ~ some_resource_type.some_resource_name
            some_attribute_name:          "3" => "4"
            another_attribute_name:       "6" => "7"
            yet_another_attribute_name:   "9" => "7"

      OUT
    end

    context 'when output contains a rebuilt resource' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
          -/+ random_id.abc (tainted)
              b64:         "e20SLHAH5CXBCw" => "<computed>"
              b64_std:     "e20SLHAH5CXBCw==" => "<computed>"
              b64_url:     "e20SLHAH5CXBCw" => "<computed>"

      TXT

      it { should == normalize_indent(<<-OUT) }
        -/+ random_id.abc (tainted)
            b64:       "e20SLHAH5CXBCw" => "<computed>"
            b64_std:   "e20SLHAH5CXBCw==" => "<computed>"
            b64_url:   "e20SLHAH5CXBCw" => "<computed>"

      OUT
    end

    context 'when output contains a rebuilt resource and no quotes' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
          -/+ random_id.abc (tainted)
              b64:         "e20SLHAH5CXBCw" => <computed>
              b64_std:     "e20SLHAH5CXBCw==" => <computed>
              b64_url:     "e20SLHAH5CXBCw" => <computed>

      TXT

      it { should == normalize_indent(<<-OUT) }
        -/+ random_id.abc (tainted)
            b64:       "e20SLHAH5CXBCw" => "<computed>"
            b64_std:   "e20SLHAH5CXBCw==" => "<computed>"
            b64_url:   "e20SLHAH5CXBCw" => "<computed>"

      OUT
    end

    context 'when output contains a resource read action' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        <= data.external.ext
            program.#: "2"
            program.0: "echo"
            program.1: "hello"
            query.%:   "<computed>"
            result.%:  "<computed>"

      TXT

      it { should == normalize_indent(<<-OUT) }
        <= data.external.ext
            program.#:   "2"
            program.0:   "echo"
            program.1:   "hello"
            query.%:     "<computed>"
            result.%:    "<computed>"

      OUT
    end

    context 'when output contains an attribute change forcing a rebuild' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        -/+ template_file.demo
            rendered: "" => "<computed>"
            template: "" => "<computed>" (forces new resource)

      TXT

      it { should == normalize_indent(<<-OUT) }
        -/+ template_file.demo
            rendered:   "" => "<computed>"
            template:   "" => "<computed>" (forces new resource)

      OUT
    end

    context 'when output contains an attribute change forcing a rebuild without quotes' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        -/+ template_file.demo
            rendered: "" => <computed>
            template: "" => <computed> (forces new resource)

      TXT

      it { should == normalize_indent(<<-OUT) }
        -/+ template_file.demo
            rendered:   "" => "<computed>"
            template:   "" => "<computed>" (forces new resource)

      OUT
    end

    context 'when output contains an attribute containing the string <computed>' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        -/+ template_file.demo
            rendered: "" => "This string contains <computed>"
            bendered: "" => "This string contains => <computed> with an arrow"
            template: "" => "This string contains <computed> in it" (forces new resource)

      TXT

      it { should == normalize_indent(<<-OUT) }
        -/+ template_file.demo
            rendered:   "" => "This string contains <computed>"
            bendered:   "" => "This string contains => <computed> with an arrow"
            template:   "" => "This string contains <computed> in it" (forces new resource)

      OUT
    end

    context 'when output contains multiple modified resources' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        ~ some_resource_type.some_resource_name
            some_attribute_name:         "3" => "4"
            another_attribute_name:      "6" => "7"
            yet_another_attribute_name:  "9" => "7"

        ~ another_resource_type.another_resource_name
            some_attribute_name:         "8" => "4"
            another_attribute_name:      "foo" => "bar"
            yet_another_attribute_name:  "hello" => "world"
      TXT

      it { should == normalize_indent(<<-OUT) }
        ~ some_resource_type.some_resource_name
            some_attribute_name:          "3" => "4"
            another_attribute_name:       "6" => "7"
            yet_another_attribute_name:   "9" => "7"

        ~ another_resource_type.another_resource_name
            some_attribute_name:          "8" => "4"
            another_attribute_name:       "foo" => "bar"
            yet_another_attribute_name:   "hello" => "world"

      OUT
    end

    context 'when output attribute name contains a space' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        + some_resource_type.some_resource_name
            some_attribute_name:                   "2"
            some_attribute.with space:             "blah"
      TXT

      it { should == normalize_indent(<<-OUT) }
        + some_resource_type.some_resource_name
            some_attribute_name:         "2"
            some_attribute.with space:   "blah"

      OUT
    end

    context 'when added resource contains an attribute with JSON' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        + aws_iam_policy.user-my-test
          arn:    "<computed>"
          name:   "user-my-test"
          path:   "/"
          policy: "{\\"Statement\\":[{\\"Effect\\":\\"Allow\\",\\"Resource\\":[\\"arn:aws:dynamodb:us-east-1:123456789012:table/my-table\\"],\\"Action\\":[\\"dynamodb:*\\",\\"s3:*\\"],\\"Condition\\":{\\"Bool\\":{\\"aws:SecureTransport\\":\\"true\\"}}},{\\"Effect\\":\\"Allow\\",\\"Resource\\":[\\"arn:aws:s3:::my-s3-development\\"],\\"Action\\":[\\"s3:*\\"],\\"Condition\\":{\\"Bool\\":{\\"aws:SecureTransport\\":\\"true\\"}}},{\\"Effect\\":\\"Deny\\",\\"Resource\\":[\\"*\\"],\\"Action\\":[\\"dynamodb:DeleteTable\\",\\"s3:DeleteBucket\\"],\\"Condition\\":{\\"Bool\\":{\\"aws:SecureTransport\\":\\"true\\"}}}],\\"Version\\":\\"2012-10-17\\"}"
      TXT

      it { should == normalize_indent(<<-OUT) }
        + aws_iam_policy.user-my-test
            arn:      "<computed>"
            name:     "user-my-test"
            path:     "/"
            policy:   {
                        "Statement": [
                          {
                            "Effect": "Allow",
                            "Resource": [
                              "arn:aws:dynamodb:us-east-1:123456789012:table/my-table"
                            ],
                            "Action": [
                              "dynamodb:*",
                              "s3:*"
                            ],
                            "Condition": {
                              "Bool": {
                                "aws:SecureTransport": "true"
                              }
                            }
                          },
                          {
                            "Effect": "Allow",
                            "Resource": [
                              "arn:aws:s3:::my-s3-development"
                            ],
                            "Action": [
                              "s3:*"
                            ],
                            "Condition": {
                              "Bool": {
                                "aws:SecureTransport": "true"
                              }
                            }
                          },
                          {
                            "Effect": "Deny",
                            "Resource": [
                              "*"
                            ],
                            "Action": [
                              "dynamodb:DeleteTable",
                              "s3:DeleteBucket"
                            ],
                            "Condition": {
                              "Bool": {
                                "aws:SecureTransport": "true"
                              }
                            }
                          }
                        ],
                        "Version": "2012-10-17"
                      }

      OUT
    end

    context 'when modified resource contains an attribute with JSON' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        ~ aws_iam_policy.my-user-test
            policy: "{\\"Statement\\":[{\\"Effect\\":\\"Allow\\",\\"Resource\\":[\\"arn:aws:dynamodb:us-east-1:123456789012:table/my-user-test\\"],\\"Action\\":[\\"dynamodb:*\\"],\\"Condition\\":{\\"Bool\\":{\\"aws:SecureTransport\\":\\"true\\"}}},{\\"Effect\\":\\"Allow\\",\\"Resource\\":[\\"arn:aws:s3:::my-s3-development\\",\\"arn:aws:s3:::my-s3-development/*\\"],\\"Action\\":[\\"s3:*\\"],\\"Condition\\":{\\"Bool\\":{\\"aws:SecureTransport\\":\\"true\\"}}},{\\"Effect\\":\\"Deny\\",\\"Resource\\":[\\"*\\"],\\"Action\\":[\\"dynamodb:DeleteTable\\",\\"s3:DeleteBucket\\"],\\"Condition\\":{\\"Bool\\":{\\"aws:SecureTransport\\":\\"true\\"}}}],\\"Version\\":\\"2012-10-17\\"}\" => \"{\\"Statement\\":[{\\"Effect\\":\\"Allow\\",\\"Resource\\":[\\"arn:aws:dynamodb:us-east-1:123456789012:table/my-user-test\\"],\\"Action\\":[\\"dynamodb:*\\",\\"s3:*\\"],\\"Condition\\":{\\"Bool\\":{\\"aws:SecureTransport\\":\\"true\\"}}},{\\"Effect\\":\\"Allow\\",\\"Resource\\":[\\"arn:aws:s3:::my-s3-development\\"],\\"Action\\":[\\"s3:*\\"],\\"Condition\\":{\\"Bool\\":{\\"aws:SecureTransport\\":\\"true\\"}}},{\\"Effect\\":\\"Deny\\",\\"Resource\\":[\\"*\\"],\\"Action\\":[\\"dynamodb:DeleteTable\\",\\"s3:DeleteBucket\\"],\\"Condition\\":{\\"Bool\\":{\\"aws:SecureTransport\\":\\"true\\"}}}],\\"Version\\":\\"2012-10-17\\"}"
      TXT

      it { should == normalize_indent(<<-OUT) }
        ~ aws_iam_policy.my-user-test
            policy:   "Effect": "Allow",
                             "Resource": [
                               "arn:aws:dynamodb:us-east-1:123456789012:table/my-user-test"
                             ],
                             "Action": [
                      -        "dynamodb:*"
                      +        "dynamodb:*",
                      +        "s3:*"
                             ],
                             "Condition": {
                               "Bool": {
                                 "aws:SecureTransport": "true"
                               }
                             }
                           },
                           {
                             "Effect": "Allow",
                             "Resource": [
                      -        "arn:aws:s3:::my-s3-development",
                      -        "arn:aws:s3:::my-s3-development/*"
                      +        "arn:aws:s3:::my-s3-development"
                             ],
                             "Action": [
                               "s3:*"
                             ],
                             "Condition": {

      OUT
    end

    context 'when computed output is included without quotes' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        + some_resource_type.some_resource_name
            id:                     <computed>
            some_attribute_name:    "foo"
      TXT

      it { should == normalize_indent(<<-OUT) }
        + some_resource_type.some_resource_name
            id:                    "<computed>"
            some_attribute_name:   "foo"

      OUT
    end
  end
end
