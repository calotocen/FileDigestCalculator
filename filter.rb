require 'csv'
require 'parslet'

class FilterParser < Parslet::Parser
    rule(:space)               { match('\s').repeat(1) }
    rule(:space?)              { space.maybe }
    rule(:identifier)          { (match('[A-Za-z]') >> match('[_0-9A-Za-z]').repeat(0)).as(:identifier) >> space? }
    rule(:integer)             { (str('-').maybe >> (str('0') | match('[1-9]') >> match('[0-9]').repeat(0))).as(:integer) >> space? }
    rule(:single_quote_string) { str("'") >> (str('\\').ignore >> match("[\\\\']") | str("'").absent? >> any).repeat.as(:single_quote_string) >> str("'") >> space? }
    rule(:double_quote_string) { str('"') >> (str('\\').ignore >> match('[\\\\"]') | str('"').absent? >> any).repeat.as(:double_quote_string) >> str('"') >> space? }
    rule(:regular_expression)  { str('/') >> (str('\\') >> any | str('/').absent? >> any).repeat.as(:regular_expression) >> str('/') >> space?  }
    rule(:string)              { single_quote_string | double_quote_string }
    rule(:binary_operator)     { (match('[<>]') >> match('=').maybe | match('[!=]') >> match('[=~]')).as(:binary_operator) >> space? }
    rule(:lhs)                 { identifier }
    rule(:rhs)                 { integer | string | regular_expression }
    rule(:filter)              { lhs.as(:lhs) >> (binary_operator.as(:operator) >> rhs.as(:rhs)).maybe }
    root :filter
end
class FilterTransform < Parslet::Transform
    rule(:identifier => simple(:identifier))                   { identifier.to_s }
    rule(:integer => simple(:integer))                         { integer.to_i }
    rule(:single_quote_string => simple(:single_quote_string)) { single_quote_string.to_s }
    rule(:double_quote_string => simple(:double_quote_string)) { double_quote_string.to_s }
    rule(:regular_expression => simple(:regular_expression))   { eval(%(/#{regular_expression}/)) }
    rule(:binary_operator => simple(:binary_operator))         { binary_operator.to_s }
    rule(:lhs => simple(:lhs))                                 { ->(rows) { rows.filter {|row| !row[lhs].nil?} } }
    rule(:rhs => simple(:rhs))                                 { rhs }
    rule(:lhs => simple(:lhs), :operator => simple(:operator), :rhs => simple(:rhs)) do
        method = rhs.method(operator.tr('<>', '><').intern)
        case lhs
        when 'index'
            lambda do |rows|
                index = -1
                rows.filter {method[index += 1]}
            end
        else
            ->(rows) { rows.filter {|row| method[row[lhs]]} }
        end
    end
end

csv_text = <<-EOS
number,text,datetime,mix
1,abcdefg,2024-02-03 11:23:34,3
2,bcdefghi,2024-03-03 13:24:34,zxcv
3,cdefgh,2024-04-03 15:33:34,2024-03-03
4,def,2024-05-03 17:21:34,11:23:44
5,efgh,2024-06-03 19:22:34,
99,f,2024-08-03 19:22:34,
EOS
csv = CSV::Table.new(CSV.new(csv_text.dup, headers: true, converters: :all).to_a)
rows = csv.each.to_a

test_cases = [
    { filter: %q(mix), expected: rows[0..3] },
    { filter: %q(number == 2), expected: rows[1..1] },
    { filter: %q(number > 1), expected: rows[1..5] },
    { filter: %q(number > 0), expected: rows[0..5] },
    { filter: %q(number < 99), expected: rows[0..4] },
    { filter: %q(text == "abcdefg"), expected: rows[0..0] },
    { filter: %q(text != 'abcdefg'), expected: rows[1..5] },
    { filter: %q(text =~ /def/), expected: rows[0..3] },
    { filter: %q(text =~ /^c/), expected: rows[2..2] },
    { filter: %q(datetime == date("2024-02-03 11:23:34")), expected: rows[2..2] },
]
parser = FilterParser.new
transform = FilterTransform.new
test_cases.each do |test_case|
    r = parser.parse(test_case[:filter])
    l = transform.apply(r)
    filtered_rows = l.call(rows)
    p filtered_rows == test_case[:expected]
end
