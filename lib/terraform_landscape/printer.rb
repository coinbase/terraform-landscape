require 'stringio'

module TerraformLandscape
  class Printer
    def initialize(output, ignore_postface: false)
      @output = output
      @ignore_postface = ignore_postface
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

      plan_output = buffer.string
      scrubbed_output = plan_output.gsub(/\e\[\d+m/, '')

      # Remove preface
      if (match = scrubbed_output.match(/^Path:[^\n]+/))
        scrubbed_output = scrubbed_output[match.end(0)..-1]
      elsif (match = scrubbed_output.match(/^(~|\+|\-)/))
        scrubbed_output = scrubbed_output[match.begin(0)..-1]
      elsif scrubbed_output.match(/^No changes/)
        @output.puts 'No changes'
        return
      else
        raise ParseError, 'Output does not contain proper preface'
      end

      # Remove postface
      if !@ignore_postface
        if (match = scrubbed_output.match(/^Plan:[^\n]+/))
          plan_summary = scrubbed_output[match.begin(0)..match.end(0)]
          scrubbed_output = scrubbed_output[0...match.begin(0)]
        else
          raise ParseError, 'Output does not container proper postface'
        end
      end

      plan = TerraformPlan.from_output(scrubbed_output)
      plan.display(@output)
      @output.puts plan_summary
    end
  end
end
