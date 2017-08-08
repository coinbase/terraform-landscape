require 'optparse'

module TerraformLandscape
  # Handles option parsing for the command line application.
  class ArgumentsParser
    # Parses command line options into an options hash.
    #
    # @param args [Array<String>] arguments passed via the command line
    #
    # @return [Hash] parsed options
    def parse(args)
      @options = {}
      @options[:command] = :pretty_print # Default command

      OptionParser.new do |parser|
        parser.banner = 'Usage: landscape [options] [plan-output-file]'

        add_info_options parser
      end.parse!(args)

      # Any remaining arguments are assumed to be the output file
      @options[:plan_output_file] = args.first

      @options
    rescue OptionParser::InvalidOption => ex
      raise InvalidCliOptionError,
            "#{ex.message}\nRun `landscape --help` to " \
            'see a list of available options.'
    end

    private

    # Register informational flags.
    def add_info_options(parser)
      parser.on('--[no-]color', 'Force output to be colorized') do |color|
        @options[:color] = color
      end

      parser.on('-d', '--debug', 'Enable debug mode for more verbose output') do
        @options[:debug] = true
      end

      parser.on_tail('-h', '--help', 'Display help documentation') do
        @options[:command] = :display_help
        @options[:help_message] = parser.help
      end

      parser.on_tail('-v', '--version', 'Display version') do
        @options[:command] = :display_version
      end

      parser.on_tail('-V', '--verbose-version', 'Display verbose version information') do
        @options[:command] = :display_version
        @options[:verbose_version] = true
      end
    end
  end
end
