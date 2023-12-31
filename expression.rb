require 'date'
require 'parslet'

class ExpressionParser < Parslet::Parser
    root(:expression)

    rule(:expression) do
        (space? >> lhs >> (operator >> rhs).maybe).as(:expression)
    end

    rule(:lhs) do
        variable.as(:lhs)
    end

    rule(:operator) do
        (
            (str('=') | str('!')) >> (str('=') | str('~')) |
            (str('<') | str('>')) >> str('=').maybe
        ).as(:operator) >> space?
    end

    rule(:rhs) do
        (
            variable >> (
                str('.') >> space? >> method_name >> (
                    str('(') >> space? >> (
                        rhs >> (str(',') >> space? >> rhs).repeat
                    ).maybe.as(:parameters) >>
                    str(')') >> space?
                ).maybe
            ).maybe.as(:method) |
            number |
            string
        ).as(:rhs)
    end

    rule(:variable) do
        (match('[_A-Za-z]') >> match('[_0-9A-Za-z]').repeat).as(:variable) >> space?
    end

    rule(:method_name) do
        (match('[_A-Za-z]') >> match('[_0-9A-Za-z]').repeat).as(:method_name) >> space?
    end

    rule(:number) do
        (
            match('[-+]').maybe >> (
                match('[1-9]') >> match('[0-9]').repeat |
                str('0')
            ) >>
            (str('.') >> match('[0-9]').repeat(1)).maybe
        ).as(:number) >> space?
    end

    rule(:string) do
        str('"') >> (
            str('\\').ignore >> any |
            str('"').absent? >> any
        ).repeat.as(:string) >> 
        str('"') >> space?
    end

    rule(:space) do
        match('[[:space:]]').repeat(1)
    end

    rule(:space?) { space.maybe }
end

class ExpressionTransform < Parslet::Transform
    rule(number: simple(:number)) do
        number.to_f
    end

    rule(string: simple(:string)) do
        string.to_s
    end

    rule(variable: simple(:variable)) do
        xs = variable.to_s
        case xs
        when 'count'
            rows.length
        when 'index'
            index
        else
            if /s$/ =~ xs && row.keys.include?(xs.slice(-1, 1).intern)
                rows.map{|r| r[xs.slice(-1, 1).intern]}
            else
                row[xs.intern]
            end
        end
    end

    rule(method_name: simple(:method_name)) do
        method_name.to_s
    end

    rule(method: simple(:method)) do
        method.to_s
    end

    rule(variable: simple(:variable), method: simple(:method)) do
        pp variable
        pp variable.eval
        pp method
    end

#    rule(lhs: simple(:x), operator: simple(:y), rhs: simple(:z)) do
#        x.method(y.to_s.intern)[z]
#    end
end

rows = [
    {:n => 1, :s => "a", :d => DateTime.parse("2023-01-01")},
    {:n => 2, :s => "b", :d => DateTime.parse("2023-01-02")},
    {:n => 3, :s => "c", :d => DateTime.parse("2023-01-03")},
]

ARGV.each do |arg|
    pp arg
    begin
        parse_result = ExpressionParser.new.parse(arg)
        pp parse_result
        rows.each_with_index do |row, i|
            dd = ExpressionTransform.new.apply(parse_result, row: row, rows: rows, index: i)
            pp dd
            pp dd[:expression][:rhs].eval
        end
    rescue
        pp $!
    end
end
