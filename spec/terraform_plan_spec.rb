require_relative './spec_helper'
require 'terraform_landscape/terraform_plan'

describe TerraformLandscape::TerraformPlan do
  describe '#display' do
    before(:all) do |example|
      String.disable_colorization = true
    end

    after(:all) do |example|
      String.disable_colorization = false
    end

    subject do
      @output = StringIO.new
      output = TerraformLandscape::Output.new(@output)
      described_class.from_output(terraform_output).display(output)
      @output.string
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

    context 'when output contains a single resource with no attributes' do
      let(:terraform_output) { normalize_indent(<<-TXT) }
        - some_resource_type.some_resource_name

      TXT

      it { should == normalize_indent(<<-OUT) }
        - some_resource_type.some_resource_name

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
  end
end
