require 'commander'

module TerraformLandscape
  # Command line application interface.
  class CLI
    include Commander::Methods

    def initialize(output)
      @output = output
    end

    # Parses the given command line arguments and executes appropriate logic
    # based on those arguments.
    #
    # @param args [Array<String>] command line arguments
    #
    # @return [Integer] exit status code
    def run(_args)
      program :name, 'Terraform Landscape'
      program :version, VERSION
      program :description, 'Pretty-print your Terraform plan output'

      define_commands

      run!
      0 # OK
    end

    private

    def define_commands
      command :print do |c|
        c.action do |_args, options|
          print(options.__hash__)
        end
        c.description = <<-TXT
  Pretty-prints your Terraform plan output.

  If an error occurs while parsing the Terraform output, print will automatically fall back on the original Terraform output. To view the stack trace instead, provide the global --trace option.
        TXT
      end

      global_option '--no-color', 'Do not output any color' do
        String.disable_colorization = true
        @output.color_enabled = false
      end

      default_command :print
    end

    def print(options)
      printer = Printer.new(@output)
      printer.process_stream(STDIN, options)
    end
  end
end
