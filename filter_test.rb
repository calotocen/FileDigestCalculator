require 'csv'
require 'minitest/autorun'
require './filter.rb'

=begin
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
    { filter: %q(datetime == datetime('2024-02-03 11:23:34')), expected: rows[0..0] },
    { filter: %q(datetime < datetime('2024-05-03')), expected: rows[0..2] },
    { filter: %q(number == min(number)), expected: rows[0..0] },
    { filter: %q(number == max(number)), expected: rows[5..5] },
    { filter: %q(count == 6), expected: rows[0..5] },
]
parser = FilterParser.new
transform = FilterTransform.new
test_cases.each do |test_case|
    r = parser.parse(test_case[:filter])
    l = transform.apply(r)
    filtered_rows = l.call(rows)
    p filtered_rows == test_case[:expected]
end
=end

class FilterTest < Minitest::Test
    def test_case_of_specifying_only_column_name
        rows = CSV::Table.new(CSV.new(<<~'EOS', headers: true, converters: :all).to_a).each.to_a
            index,text
            0,aaa
            1,bbb
            2,
            3,ccc
            4,
            5,ddd
            6,eee
            7,
        EOS

        expected_rows = [0, 1, 3, 5, 6].map{ |index| rows[index] }
        filter = Filter::generate('text')
        actual_rows = filter.call(rows)
        assert_equal(expected_rows, actual_rows)
    end
    
    def test_case_of_filtering_integer
        rows = CSV::Table.new(CSV.new(<<~'EOS', headers: true, converters: :all).to_a).each.to_a
            index,integer
            0,-100
            1,-99
            2,-1
            3,0
            4,1
            5,99
            6,100
            7,1000000
        EOS

        expected_rows = [0].map{ |index| rows[index] }
        filter = Filter::generate('integer == -100')
        actual_rows = filter.call(rows)
        assert_equal(expected_rows, actual_rows)

        expected_rows = [1, 2, 3, 4, 5, 6, 7].map{ |index| rows[index] }
        filter = Filter::generate('integer != -100')
        actual_rows = filter.call(rows)
        assert_equal(expected_rows, actual_rows)

        expected_rows = [2, 3, 4, 5, 6, 7].map{ |index| rows[index] }
        filter = Filter::generate('integer > -99')
        actual_rows = filter.call(rows)
        assert_equal(expected_rows, actual_rows)

        expected_rows = [1, 2, 3, 4, 5, 6, 7].map{ |index| rows[index] }
        filter = Filter::generate('integer >= -99')
        actual_rows = filter.call(rows)
        assert_equal(expected_rows, actual_rows)

        expected_rows = [0, 1, 2].map{ |index| rows[index] }
        filter = Filter::generate('integer < 0')
        actual_rows = filter.call(rows)
        assert_equal(expected_rows, actual_rows)

        expected_rows = [0, 1, 2, 3, 4].map{ |index| rows[index] }
        filter = Filter::generate('integer <= 1')
        actual_rows = filter.call(rows)
        assert_equal(expected_rows, actual_rows)

        expected_rows = [].map{ |index| rows[index] }
        filter = Filter::generate('integer > 1000000')
        actual_rows = filter.call(rows)
        assert_equal(expected_rows, actual_rows)
    end
end
