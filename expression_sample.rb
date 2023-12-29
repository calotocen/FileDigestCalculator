require 'parslet'

class ExpressionParser < Parslet::Parser
    root(:expression)

    rule(:expression) do
        rhs.as(:expression)
    end

    rule(:rhs) do
        integral_literal | string_literal
    end

    rule(:integral_literal) do
        (match('[1-9]') >> match('[0-9]').repeat | str('0')).as(:integral_literal)
    end

    rule(:string_literal) do
        str('"') >> (
            str('\\').ignore >> any | str('"').absent? >> any
        ).repeat.as(:string_literal) >> str('"')
    end
end

IntegralLiteral = Struct.new(:integral_literal) do
    def eval
        integral_literal.to_i
    end
end
StringLiteral = Struct.new(:string_literal) do
    def eval
        string_literal.to_s
    end
end
class ExpressionTransform < Parslet::Transform
    rule(integral_literal: simple(:integral_literal)) do
        IntegralLiteral.new(integral_literal)
    end

    rule(string_literal: simple(:string_literal)) do
        StringLiteral.new(string_literal)
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