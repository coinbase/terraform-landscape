require 'colorize'
require 'diffy'
require 'json'
require 'treetop'

########################################################################
# Represents the parsed output of `terraform plan`.
#
# This allows us to easily inspect the plan and present a more readable
# explanation of the plan to the user.
########################################################################
class TerraformLandscape::TerraformPlan # rubocop:disable Metrics/ClassLength
  GRAMMAR_FILE = File.expand_path(File.join(File.dirname(__FILE__),
                                            '..', '..', 'grammar',
                                            'terraform_plan.treetop'))

  CHANGE_SYMBOL_TO_COLOR = {
    :~ => :yellow,
    :- => :red,
    :+ => :green,
    :'-/+' => :yellow,
    :'<=' => :cyan
  }.freeze

  DEFAULT_DIFF_CONTEXT_LINES = 5

  class ParseError < StandardError; end

  class << self
    def from_output(string)
      # Our grammar assumes output with Unix line endings
      string = string.gsub("\r\n", "\n")

      return new([]) if string.strip.empty?
      tree = parser.parse(string)
      raise ParseError, parser.failure_reason unless tree
      new(tree.to_ast)
    end

    private

    def parser
      @parser ||=
        begin
          Treetop.load(GRAMMAR_FILE)
          TerraformPlanParser.new
        end
    end
  end

  # Create a plan from an abstract syntax tree (AST).
  def initialize(plan_ast, options = {})
    @ast = plan_ast
    @diff_context_lines = options.fetch(:diff_context_lines, DEFAULT_DIFF_CONTEXT_LINES)
  end

  def display(output)
    @out = output
    @ast.each do |resource|
      display_resource(resource)
      @out.newline
    end
  end

  private

  def display_resource(resource)
    change_color = CHANGE_SYMBOL_TO_COLOR[resource[:change]]

    resource_header = "#{resource[:change]} #{resource[:resource_type]}." \
                      "#{resource[:resource_name]}".colorize(change_color)
    resource_header += " (#{resource[:reason]})".colorize(:magenta) if resource[:reason]

    @out.puts resource_header

    # Determine longest attribute name so we align all values at same indentation
    attribute_value_indent_amount = attribute_indent_amount_for_resource(resource)

    resource[:attributes].each do |attribute_name, attribute_value_and_reason|
      attribute_value = attribute_value_and_reason[:value]
      attribute_change_reason = attribute_value_and_reason[:reason]
      display_attribute(resource,
                        change_color,
                        attribute_name,
                        attribute_value,
                        attribute_change_reason,
                        attribute_value_indent_amount)
    end
  end

  def attribute_indent_amount_for_resource(resource)
    longest_name_length = resource[:attributes].keys.reduce(0) do |longest, name|
      name.length > longest ? name.length : longest
    end
    longest_name_length + 8
  end

  def json?(value)
    ['{', '['].include?(value.to_s[0]) &&
      (JSON.parse(value) rescue nil) # rubocop:disable Style/RescueModifier
  end

  def to_pretty_json(value)
    # Can't JSON.parse an empty string, so handle it separately
    return '' if value.strip.empty?

    JSON.pretty_generate(JSON.parse(value),
                         {
                           indent: '  ',
                           space: ' ',
                           object_nl: "\n",
                           array_nl: "\n"
                         })
  end

  def display_diff(old, new, indent)
    @out.print Diffy::Diff.new(old, new, { context: @diff_context_lines })
      .to_s(String.disable_colorization ? :text : :color)
      .gsub("\n", "\n" + indent)
      .strip
  end

  def display_attribute(
    resource,
    change_color,
    attribute_name,
    attribute_value,
    attribute_change_reason,
    attribute_value_indent_amount
  )
    attribute_value_indent = ' ' * attribute_value_indent_amount

    if [:~, :'-/+'].include?(resource[:change])
      display_modified_attribute(change_color,
                                 attribute_name,
                                 attribute_value,
                                 attribute_change_reason,
                                 attribute_value_indent,
                                 attribute_value_indent_amount)
    else
      display_added_or_removed_attribute(change_color,
                                         attribute_name,
                                         attribute_value,
                                         attribute_value_indent,
                                         attribute_value_indent_amount)
    end
  end

  def display_modified_attribute( # rubocop:disable Metrics/MethodLength
    change_color,
    attribute_name,
    attribute_value,
    attribute_change_reason,
    attribute_value_indent,
    attribute_value_indent_amount
  )
    # Since the attribute line is always of the form
    # "old value" => "new value", we can add curly braces and parse with
    # `eval` to obtain a hash with a single key/value.
    old, new = eval("{#{attribute_value}}").to_a.first # rubocop:disable Security/Eval

    return if old == new # Don't show unchanged attributes

    @out.print "    #{attribute_name}:".ljust(attribute_value_indent_amount, ' ')
      .colorize(change_color)

    if json?(new)
      # Value looks like JSON, so prettify it to make it more readable
      fancy_old = "#{to_pretty_json(old)}\n"
      fancy_new = "#{to_pretty_json(new)}\n"
      display_diff(fancy_old, fancy_new, attribute_value_indent)
    elsif old.include?("\n") || new.include?("\n")
      # Multiline content, so display nicer diff
      display_diff("#{old}\n", "#{new}\n", attribute_value_indent)
    else
      # Typical values, so just show before/after
      @out.print '"' + old.colorize(:red) + '"'
      @out.print ' => '.colorize(:light_black)
      @out.print '"' + new.colorize(:green) + '"'
    end

    @out.print " (#{attribute_change_reason})".colorize(:magenta) if attribute_change_reason

    @out.newline
  end

  def display_added_or_removed_attribute(
    change_color,
    attribute_name,
    attribute_value,
    attribute_value_indent,
    attribute_value_indent_amount
  )
    @out.print "    #{attribute_name}:".ljust(attribute_value_indent_amount, ' ')
      .colorize(change_color)

    evaluated_string = eval(attribute_value) # rubocop:disable Security/Eval
    if json?(evaluated_string)
      @out.print to_pretty_json(evaluated_string).gsub("\n",
                                                       "\n#{attribute_value_indent}")
        .colorize(change_color)
    else
      @out.print "\"#{evaluated_string.colorize(change_color)}\""
    end

    @out.newline
  end
end
