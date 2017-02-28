# Terraform Landscape

Terraform Landscape is a tool for reformatting the output of `terraform plan`
to be easier to read and understand.

#### Before
<img src="https://raw.githubusercontent.com/coinbase/terraform-landscape/master/doc/before.png" width="65%" alt="Original Terraform plan output" />

### After
<img src="https://raw.githubusercontent.com/coinbase/terraform-landscape/master/doc/after.png" width="65%" alt="Improved Terraform plan output" />

* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)

## Requirements

* Ruby 2+

## Installation

The `landscape` executable is installed via [RubyGems](https://rubygems.org/).

```bash
gem install terraform_landscape
```

## Usage

Pipe the output of `terraform plan` into `landscape` to reformat the output.

```bash
terraform plan ... | landscape
```

## License

This project is released under the [Apache 2.0 license](LICENSE).
