require 'stringio'

module TerraformLandscape
  # Takes output from Terraform executable and outputs it in a prettified
  # format.
  class Printer
    def initialize(output)
      @output = output
    end

    def process_stream(io, options = {}) # rubocop:disable Metrics/MethodLength
      apply = nil
      buffer = StringIO.new
      original_tf_output = StringIO.new
      begin
        block_size = 1024

        done = false
        until done
          readable_fds, = IO.select([io])
          next unless readable_fds

          readable_fds.each do |f|
            begin
              new_output = f.read_nonblock(block_size)
              original_tf_output << new_output
              buffer << strip_ansi(new_output)
            rescue IO::WaitReadable # rubocop:disable Lint/HandleExceptions
              # Ignore; we'll call IO.select again
            rescue EOFError
              done = true
            end
          end

          apply = apply_prompt(buffer.string.encode('UTF-8',
                                                    invalid: :replace,
                                                    replace: ''))
          done = true if apply
        end

        begin
          process_string(buffer.string)
          @output.print apply if apply
        rescue ParseError, TerraformPlan::ParseError => e
          raise e if options[:trace]

          @output.warning FALLBACK_MESSAGE
          @output.print original_tf_output.string
        end

        @output.write_from(io)
      ensure
        io.close
      end
    end

    def process_string(plan_output) # rubocop:disable Metrics/MethodLength
      scrubbed_output = strip_ansi(plan_output)

      # Our grammar assumes output with Unix line endings
      scrubbed_output.gsub!("\r\n", "\n")

      # Remove initialization messages like
      # "- Downloading plugin for provider "aws" (1.1.0)..."
      # "- module.base_network"
      # as these break the parser which thinks "-" is a resource deletion
      scrubbed_output.gsub!(/^- .*\.\.\.$/, '')
      scrubbed_output.gsub!(/^- module\..*$/, '')

      # Remove separation lines that appear after refreshing state
      scrubbed_output.gsub!(/^-+$/, '')

      if (matches = scrubbed_output.scan(/^Warning:.*$/))
        matches.each do |warning|
          @output.puts warning.colorize(:yellow)
        end
      end

      # Remove preface
      if (match = scrubbed_output.match(/^Path:[^\n]+/))
        scrubbed_output = scrubbed_output[match.end(0)..-1]
      elsif (match = scrubbed_output.match(/^Terraform.+following\sactions:/))
        scrubbed_output = scrubbed_output[match.end(0)..-1]
      elsif (match = scrubbed_output.match(/^\s*(~|\+|\-)/))
        scrubbed_output = scrubbed_output[match.begin(0)..-1]
      elsif scrubbed_output =~ /^(No changes\.|This plan does nothing)/
        @output.puts 'No changes.'
        return
      else
        raise ParseError, 'Output does not contain proper preface'
      end

      # Remove postface
      if (match = scrubbed_output.match(/^Plan:[^\n]+/))
        plan_summary = scrubbed_output[match.begin(0)..match.end(0)]
        scrubbed_output = scrubbed_output[0...match.begin(0)]
      end

      plan = TerraformPlan.from_output(scrubbed_output)
      plan.display(@output)
      @output.puts plan_summary
    end

    private

    def strip_ansi(string)
      string.gsub(/\e\[\d+m/, '')
    end

    def apply_prompt(output)
      return unless output =~ /Enter a value:\s+$/
      output[/Do you want to perform these actions.*$/m, 0]
    end
  end
end
