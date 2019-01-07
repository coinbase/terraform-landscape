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
        c.action do |args, options|
          print(options.__hash__)
        end
        c.option '--fallback', 'Fallback on original Terraform output when an error occurs while parsing'
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