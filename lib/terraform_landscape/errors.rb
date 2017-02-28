# Collection of errors that can be raised by the framework.
module TerraformLandscape
  # Abstract error. Separates LintTrappings errors from other kinds of
  # errors in the exception hierarchy.
  #
  # @abstract
  class Error < StandardError
    # Returns the status code that should be output if this error goes
    # unhandled.
    #
    # Ideally these should resemble exit codes from the sysexits documentation
    # where it makes sense.
    def self.exit_status(*args)
      if args.any?
        @exit_status = args.first
      elsif @exit_status
        @exit_status
      else
        ancestors.each do |ancestor|
          return 70 if ancestor == TerraformLandscape::Error # No exit status defined
          return ancestor.exit_status if ancestor.exit_status
        end
      end
    end

    def exit_status
      self.class.exit_status
    end
  end

  # Raised when there was a problem parsing a document.
  class ParseError < Error; end
end
