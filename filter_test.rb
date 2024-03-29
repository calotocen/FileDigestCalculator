require 'csv'
require 'minitest/autorun'
require_relative 'filter.rb'

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

    def test_case_of_special_column
        rows = CSV::Table.new(CSV.new(<<~'EOS', headers: true, converters: :all).to_a).each.to_a
            id
            0
            1
            2
        EOS

        expected_rows = [0, 1, 2].map{ |index| rows[index] }
        filter = Filter::generate('count == 3')
        actual_rows = filter.call(rows)
        assert_equal(expected_rows, actual_rows)

        expected_rows = [1].map{ |index| rows[index] }
        filter = Filter::generate('index == 1')
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

        expected_rows = [0].map{ |index| rows[index] }
        filter = Filter::generate('integer == min(integer)')
        actual_rows = filter.call(rows)
        assert_equal(expected_rows, actual_rows)

        expected_rows = [7].map{ |index| rows[index] }
        filter = Filter::generate('integer == max(integer)')
        actual_rows = filter.call(rows)
        assert_equal(expected_rows, actual_rows)
    end

    def test_case_of_filtering_text
        rows = CSV::Table.new(CSV.new(<<~'EOS', headers: true, converters: :all).to_a).each.to_a
            index,text
            0,aaa\'
            1,"bbbb\"""
            2,cc
            3,ddddd
            4,e
            5,fff
            6,gggaaaa
            7,hhhh
        EOS

        expected_rows = [0].map{ |index| rows[index] }
        filter = Filter::generate(%(text == 'aaa\\\\\\''))
        actual_rows = filter.call(rows)
        assert_equal(expected_rows, actual_rows)

        expected_rows = [0, 2, 3, 4, 5, 6, 7].map{ |index| rows[index] }
        filter = Filter::generate(%(text != "bbbb\\\\\\""))
        actual_rows = filter.call(rows)
        assert_equal(expected_rows, actual_rows)

        expected_rows = [0, 2, 5, 6].map{ |index| rows[index] }
        filter = Filter::generate(%(text =~ /^[acfg]/))
        actual_rows = filter.call(rows)
        assert_equal(expected_rows, actual_rows)

        expected_rows = [0, 1, 3, 4, 7].map{ |index| rows[index] }
        filter = Filter::generate(%(text !~ /[acfg]$/))
        actual_rows = filter.call(rows)
        assert_equal(expected_rows, actual_rows)
    end

    def test_case_of_filtering_datetime
        rows = CSV::Table.new(CSV.new(<<~'EOS', headers: true, converters: :all).to_a).each.to_a
            index,time
            0,2024-01-01 00:00:00
            1,2024-02-02
            2,2024-02-02 01:01:01
            3,2024-04-04 04:04:04
            4,2024-04-04 04:04:05
            5,2025-05-05 05:05:05
            6,2026-06-06 06:06:06
        EOS

        expected_rows = [0].map{ |index| rows[index] }
        filter = Filter::generate("time == datetime('2024-01-01 00:00:00')")
        actual_rows = filter.call(rows)
        assert_equal(expected_rows, actual_rows)

        expected_rows = [0, 1].map{ |index| rows[index] }
        filter = Filter::generate("time <= datetime('2024-02-02')")
        actual_rows = filter.call(rows)
        assert_equal(expected_rows, actual_rows)

        expected_rows = [4, 5, 6].map{ |index| rows[index] }
        filter = Filter::generate("time > datetime('2024-04-04 04:04:04')")
        actual_rows = filter.call(rows)
        assert_equal(expected_rows, actual_rows)
    end
end
