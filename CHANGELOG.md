# Terraform Landscape Change Log

## 0.3.4

* Fix syntax errors when running on Ruby 3

## 0.3.3

* Fix handling of Windows newlines in preprocessing step

## 0.3.2

* Fix handling of UTF-8 strings in Terraform plans

## 0.3.1

* Fix handling of initialization messages for included modules

## 0.3.0

* Display original Terraform output when Landscape encounters an unhandled exception
* Drop dependency on `string_undump` gem in favor of built in `String#undump` method
  introduced in Ruby 2.5
* Require Ruby 2.5 or newer

## 0.2.2

* Fix output parser to show changed sensitive values
* Fix plan parser to not extract attributes using `eval`
* Include warning messages in output

## 0.2.1

* Include period after `No changes` to maximize output compatibility
* Fix output parser to work with Terraform workspaces
* Fix output parser to work around multi-byte UTF-8 characters in certain scenarios

## 0.2.0

* Sort JSON by keys before generating diff

## 0.1.18

* Allow confirming `terraform apply` prompt

## 0.1.17

* Fix handling of dashed line separators after state refresh output

## 0.1.16

* Fix handling of initialization messages output by `terraform init`

## 0.1.15

* Update the support for unquoted bracketed output to work with `<sensitive>` fields

## 0.1.14

* Fix handling of `This plan does nothing` output

## 0.1.13

* Fix processing of resource changes with `(new resource required)` explanation

## 0.1.12

* Fix processing attribute names that include colons

## 0.1.11

* Fix handling of `<computed>` attribute values with Terraform 0.10.4+

## 0.1.10

* Fix handling of attribute names with spaces

## 0.1.9

* Fix handling of additional indentation in Terraform 0.10.0 output

## 0.1.8

* Fix handling of Terraform plan outputs when `-out` flag not specified

## 0.1.7

* Gracefully handle case where Terraform output does not contain postface

## 0.1.6

* Fix handling of read action resources (`<=`)

## 0.1.5

* Fix handling of Windows line endings

## 0.1.4

* Fix handling of repeated resources with index numbers
* Fix changing resource attributes from empty string to JSON
* Fix handling of consecutive resources with no attributes

## 0.1.3

* Fix handling of resources rebuilt due to attribute changes with
  `(forces new resource)` in output

## 0.1.2

* Fix handling of rebuilt/tainted resources

## 0.1.1

* Fix handling of resources with no attributes

## 0.1.0

* Don't require `-out` flag on Terraform command
* Fix handling of Terraform output with no changes

## 0.0.1

* Initial release
