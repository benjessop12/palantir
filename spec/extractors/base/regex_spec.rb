# frozen_string_literal: true

require_relative '../../../lib/palantir'

describe Palantir::Extractors::Base::Regex do
  context 'the general API' do
    describe 'code_from' do
      shared_examples_for 'extract code' do
        it 'extracts the string according to its format' do
          expect(described_class.code_from(string: test_string)).to eq(expected_output)
        end
      end

      context 'the stock code is in XXX format' do
        include_examples 'extract code' do
          let(:test_string) { 'the stock code NIO is present' }
          let(:expected_output) { 'NIO' }
        end
      end

      context 'the stock code is in XXXX format' do
        include_examples 'extract code' do
          let(:test_string) { 'the stock code PLTR is present' }
          let(:expected_output) { 'PLTR' }
        end
      end

      context 'there is a hashtag present' do
        include_examples 'extract code' do
          let(:test_string) { '#NICE the stock code PLTR is present' }
          let(:expected_output) { 'PLTR' }
        end
      end

      context 'there is no stock code present' do
        include_examples 'extract code' do
          let(:test_string) { 'there is no stock code present' }
          let(:expected_output) { '' }
        end
      end
    end

    describe 'currency_from' do
      shared_examples_for 'extract currency' do
        it 'extracts the string according to its format' do
          expect(described_class.currency_from(string: currency_string)).to eq(expected_output)
        end
      end

      context 'the string currency is at the end of the string' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the present value is $4.20' }
          let(:expected_output) { '$4.20' }
        end
      end

      context 'the string currency is in $x.xx format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value $4.00 is present' }
          let(:expected_output) { '$4.00' }
        end
      end

      context 'the string currency is in $xx.xx format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value $40.00 is present' }
          let(:expected_output) { '$40.00' }
        end
      end

      context 'the string currency is in $xxx.xx format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value $400.00 is present' }
          let(:expected_output) { '$400.00' }
        end
      end

      context 'the string currency is in £x.xx format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value £4.00 is present' }
          let(:expected_output) { '£4.00' }
        end
      end

      context 'the string currency is in $x,xx format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value $4,00 is present' }
          let(:expected_output) { '$4,00' }
        end
      end

      context 'the string currency is in $xx,xx format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value $40,00 is present' }
          let(:expected_output) { '$40,00' }
        end
      end

      context 'the string currency is in $xxx,xx format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value $400,00 is present' }
          let(:expected_output) { '$400,00' }
        end
      end

      context 'the string currency is in $x,xx format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value $4,00 is present' }
          let(:expected_output) { '$4,00' }
        end
      end

      context 'the string currency is in $x format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value $4 is present' }
          let(:expected_output) { '$4' }
        end
      end

      context 'the string currency is in $xx format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value $40 is present' }
          let(:expected_output) { '$40' }
        end
      end

      context 'the string currency is in $xxx format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value $400 is present' }
          let(:expected_output) { '$400' }
        end
      end

      context 'the string currency is in £x format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value £4 is present' }
          let(:expected_output) { '£4' }
        end
      end

      context 'the string currency is in x format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value 4 is present' }
          let(:expected_output) { '4' }
        end
      end

      context 'the string currency is in xx format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value 40 is present' }
          let(:expected_output) { '40' }
        end
      end

      context 'the string currency is in xxx format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value 400 is present' }
          let(:expected_output) { '400' }
        end
      end

      context 'the string currency is in x.xx format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value 4.00 is present' }
          let(:expected_output) { '4.00' }
        end
      end

      context 'the string currency is in xx.xx format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value 40.00 is present' }
          let(:expected_output) { '40.00' }
        end
      end

      context 'the string currency is in xxx.xx format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value 400.00 is present' }
          let(:expected_output) { '400.00' }
        end
      end

      context 'the string currency is in x,xxx format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value 4,000 is present' }
          let(:expected_output) { '4,000' }
        end
      end

      context 'the string currency is in xx,xxx format' do
        include_examples 'extract currency' do
          let(:currency_string) { 'the value 44,000 is present' }
          let(:expected_output) { '44,000' }
        end
      end

      context 'the string currency is in xxx format and contents with percentage numeric' do
        include_examples 'extract currency' do
          let(:currency_string) { '100%% the value 44,000 is present' }
          let(:expected_output) { '44,000' }
        end
      end

      context 'the string currency is not present' do
        include_examples 'extract currency' do
          let(:currency_string) { 'there is no currency present' }
          let(:expected_output) { '' }
        end
      end
    end

    describe 'date_from' do
      shared_examples_for 'extract date' do
        it 'extracts the date according to its format' do
          expect(described_class.date_from(string: test_string)).to eq(expected_output)
        end
      end

      context 'the date sits at the end of the string' do
        include_examples 'extract date' do
          let(:test_string) { 'tsla rose to $4.20 on 20/4' }
          let(:expected_output) { '4-20' }
        end
      end

      context 'the month is before the day in the date' do
        include_examples 'extract date' do
          let(:test_string) { 'tsla rose to $4.20 on 4/20' }
          let(:expected_output) { '4-20' }
        end
      end

      context 'the date sits in a string before a currency' do
        include_examples 'extract date' do
          let(:test_string) { 'on the date 20/4, tsla rose to $4.20' }
          let(:expected_output) { '4-20' }
        end
      end

      context 'the date sits in a string after a currency' do
        include_examples 'extract date' do
          let(:test_string) { 'tsla rose to $4.20, on the date 20/4' }
          let(:expected_output) { '4-20' }
        end
      end
    end

    describe 'convert_date' do
      shared_examples_for 'date conversion' do
        it 'extracts the date and assumes the format' do
          expect(described_class.convert_date(date: test_date_string)).to eq(expected_output)
        end
      end

      context 'when the date juxtaposition is clear' do
        include_examples 'date conversion' do
          let(:test_date_string) { '4/20' }
          let(:expected_output) { '4-20' }
        end
      end

      context 'when the date is unclear' do
        include_examples 'date conversion' do
          let(:test_date_string) { '3/4' }
          let(:expected_output) { '3-4' }
        end
      end
    end

    describe 'assert_parsing' do
      context 'when the date_array contains clearly defined strings' do
        it 'returns true' do
          expect(described_class.assert_parsing(date_array: %w[20 4])).to eq(true)
        end
      end

      context 'when the date_array does not contain clearly defined strings' do
        it 'returns false' do
          expect(described_class.assert_parsing(date_array: %w[3 4])).to eq(false)
        end
      end
    end
  end
end
