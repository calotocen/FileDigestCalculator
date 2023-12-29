require 'parslet'

class ExpressionParser < Parslet::Parser
    root(:expression)

    rule(:expression) do
        integral_literal.as(:expression)
    end

    rule(:integral_literal) do
        (match('[1-9]') >> match('[0-9]').repeat | str('0')).as(:integral_literal)
    end
end

IntegralLiteral = Struct.new(:integral_literal) do
    def eval
        integral_literal.to_i
    end
end
class ExpressionTransform < Parslet::Transform
    rule(integral_literal: simple(:integral_literal)) do
        IntegralLiteral.new(integral_literal)
    end

    rule(expression: simple(:expression)) do
        expression
    end
end

parser = ExpressionParser.new
transform = ExpressionTransform.new
ARGV.each do |arg|
    begin
        pp '----------'
        pp arg
        intermediary_tree = parser.parse(arg)
        pp intermediary_tree
        abstract_syntax_tree = transform.apply(intermediary_tree)
        pp abstract_syntax_tree
        pp abstract_syntax_tree.eval
    rescue
        pp $!
    end
end