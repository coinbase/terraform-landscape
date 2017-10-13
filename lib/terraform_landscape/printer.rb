require 'stringio'

module TerraformLandscape
  # Takes output from Terraform executable nad outputs it in a prettified
  # format.
  class Printer
    def initialize(output)
      @output = output
    end

    def process_stream(io)
      buffer = StringIO.new
      begin
        block_size = 1024

        done = false
        until done
          readable_fds, = IO.select([io])
          next unless readable_fds

          readable_fds.each do |f|
            begin
              buffer << f.read_nonblock(block_size)
            rescue IO::WaitReadable # rubocop:disable Lint/HandleExceptions
              # Ignore; we'll call IO.select again
            rescue EOFError
              done = true
            end
          end
        end
      ensure
        io.close
      end

      process_string(buffer.string)
    end

    def process_string(plan_output)
      scrubbed_output = plan_output.gsub(/\e\[\d+m/, '').gsub(/^-{72}\n{2}/, '')

      if scrubbed_output =~ /^(No changes. Infrastructure is up-to-date|This plan does nothing)/
        @output.puts 'No changes'
        return
      end

      # Remove preface
      if (match = scrubbed_output.match(/^Path:[^\n]+/))
        scrubbed_output = scrubbed_output[match.end(0)..-1]
      elsif (match = scrubbed_output.match(/^Terraform.+following\sactions:/))
        scrubbed_output = scrubbed_output[match.end(0)..-1]
      elsif (match = scrubbed_output.match(/^\s*(~|\+|\-)/))
        scrubbed_output = scrubbed_output[match.begin(0)..-1]
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
  end
end
