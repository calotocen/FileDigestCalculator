require 'csv'
require 'parslet'

class Filter
    class Parser < Parslet::Parser
        rule(:space)               { match('\s').repeat(1) }
        rule(:space?)              { space.maybe }
        rule(:left_parenthesis)    { str('(') >> space? }
        rule(:right_parenthesis)   { str(')') >> space? }
        rule(:identifier)          { (match('[A-Za-z]') >> match('[_0-9A-Za-z]').repeat(0)).as(:identifier) >> space? }
        rule(:integer)             { (str('-').maybe >> (str('0') | match('[1-9]') >> match('[0-9]').repeat(0))).as(:integer) >> space? }
        rule(:single_quote_string) { str("'") >> (str('\\').ignore >> match("[\\\\']") | str("'").absent? >> any).repeat.as(:single_quote_string) >> str("'") >> space? }
        rule(:double_quote_string) { str('"') >> (str('\\').ignore >> match('[\\\\"]') | str('"').absent? >> any).repeat.as(:double_quote_string) >> str('"') >> space? }
        rule(:regular_expression)  { str('/') >> (str('\\') >> any | str('/').absent? >> any).repeat.as(:regular_expression) >> str('/') >> space?  }
        rule(:string)              { single_quote_string | double_quote_string }
        rule(:function_call)       { identifier.as(:function_name) >> left_parenthesis >> (integer | string | identifier).as(:argument) >> right_parenthesis }
        rule(:binary_operator)     { (match('[<>]') >> match('=').maybe | match('[!=]') >> match('[=~]')).as(:binary_operator) >> space? }
        rule(:lhs)                 { identifier }
        rule(:rhs)                 { integer | string | regular_expression | function_call }
        rule(:filter)              { lhs.as(:lhs) >> (binary_operator.as(:operator) >> rhs.as(:rhs)).maybe }
        root :filter
    end
    private_constant :Parser

    class Transform < Parslet::Transform
        rule(:identifier => simple(:identifier))                   { identifier.to_s }
        rule(:integer => simple(:integer))                         { integer.to_i }
        rule(:single_quote_string => simple(:single_quote_string)) { single_quote_string.to_s }
        rule(:double_quote_string => simple(:double_quote_string)) { double_quote_string.to_s }
        rule(:regular_expression => simple(:regular_expression))   { eval(%(/#{regular_expression}/)) }
        rule(:binary_operator => simple(:binary_operator))         { binary_operator.to_s }
        rule(:lhs => simple(:lhs))                                 { ->(rows) { rows.filter {|row| !row[lhs].nil?} } }
        rule(:rhs => simple(:rhs))                                 { rhs }
        rule(:function_name => simple(:function_name), :argument => simple(:argument)) do
            case function_name
            when 'datetime'
                DateTime.parse(argument)
            when 'min', 'max'
                ->(rows) { rows.map{|row| row[argument]}.method(function_name).call() }
            end
        end
        rule(:lhs => simple(:lhs), :operator => simple(:operator), :rhs => simple(:rhs)) do
            if rhs.instance_of?(Proc)
                # the operator must be reversed to swap the left and right operands.
                # rows specified for the following lambda must not be empty.
                method_factory = ->(rows) { rhs.call(rows).method(operator.tr('<>', '><').intern) }
                lambda do |rows|
                    return [] if rows.empty?
                    method = method_factory.call(rows)
                    rows.filter {|row| method.call(row[lhs])}
                end
            else
                # the operator must be reversed to swap the left and right operands.
                method = rhs.method(operator.tr('<>', '><').intern)
                case lhs
                when 'index'
                    lambda do |rows|
                        index = -1
                        rows.filter { method.call(index += 1) }
                    end
                when 'count'
                    ->(rows) { method.call(rows.length) ? rows : [] }
                else
                    ->(rows) { rows.filter {|row| method.call(row[lhs])} }
                end
            end
        end
    end
    private_constant :Transform

    def self.generate(filter)
        parser = Parser.new
        parsed_filter = parser.parse(filter)
        transform = Transform.new
        return transform.apply(parsed_filter)
    end
end
