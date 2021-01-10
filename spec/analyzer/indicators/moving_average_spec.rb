# frozen_string_literal: true

require_relative '../../../lib/palantir'

describe Palantir::Analyzer::Indicators::MovingAverage do
  before do
    stub_const('ENV', 'TEST' => 'true')
  end

  context 'when given data' do
    let(:base_data_array) { [*1..20] }
    let(:base_dummy_class) { described_class.new(input_data: base_data_array, ticker: 'PLTR') }

    describe 'simple' do
      it 'returns an accurate simple moving average' do
        expect(base_dummy_class.simple).to eq(10)
      end
    end

    describe 'exponential' do
      context 'when the input data is on a strong uptrend' do
        before do
          allow(base_dummy_class).to receive(:first_time?).and_return(false)
        end

        it 'provides an accurate exponential moving average' do
          expect(base_dummy_class.exponential.ceil(4)).to eq(0.1765)
        end
      end
    end

    describe 'exponential primer' do
      context 'when scope is current' do
        it 'returns the exponential primer value for calculating current exponential moving average' do
          expect(base_dummy_class.send(:exponential_primer, scope: :current).ceil(4)).to eq(0.0908)
        end
      end

      context 'when scope is former' do
        it 'returns the exponential primer value for calculating former exponential moving average' do
          expect(base_dummy_class.send(:exponential_primer, scope: :former).ceil(4)).to eq(0.0862)
        end
      end
    end

    describe 'previous_ema' do
      context 'when first time calculating ema' do
        before do
          allow(base_dummy_class).to receive(:first_time?).and_return(true)
          allow(base_dummy_class).to receive(:simple)
        end

        it 'uses simple moving average as previous exponential' do
          base_dummy_class.send(:previous_ema)
          expect(base_dummy_class).to have_received(:simple).once
        end
      end

      context 'when not first time calculating ema' do
        before do
          allow(base_dummy_class).to receive(:first_time?).and_return(false)
          allow(base_dummy_class).to receive(:exponential_primer)
        end

        it 'calculates previous exponential' do
          base_dummy_class.send(:previous_ema)
          expect(base_dummy_class).to have_received(:exponential_primer).once
        end
      end
    end

    describe 'first_time?' do
      context 'when the var exists in the database' do
        before do
          allow(Palantir::Database).to receive(:get_var).and_return([['something']])
        end

        it 'returns true' do
          expect(base_dummy_class.send(:first_time?)).to eq(true)
        end
      end

      context 'when the var does not exist in the database' do
        before do
          allow(Palantir::Database).to receive(:get_var).and_return([[]])
        end

        it 'returns false' do
          expect(base_dummy_class.send(:first_time?)).to eq(false)
        end
      end
    end

    describe 'mark_ticker' do
      before do
        allow(Palantir::Database).to receive(:save_var)
      end

      it 'sends a request to the databse' do
        base_dummy_class.send(:mark_ticker, value: 'value')
        expect(Palantir::Database).to have_received(:save_var).with(name: 'PLTR', value: 'value')
      end
    end

    describe 'weighting' do
      it 'returns weighting based on input data array size' do
        expect(base_dummy_class.send(:weighting).ceil(4)).to eq(0.9955)
      end
    end

    describe 'smooth_factor' do
      it 'returns an accurate smooth factor for division base on input data count' do
        expect(base_dummy_class.send(:smooth_factor).ceil(4)).to eq(0.0953)
      end

      context 'when given a large array' do
        let(:fixnum_max) { (2**(0.size * 8 - 2) - 1) }

        before do
          base_dummy_class.instance_variable_set(:@count, fixnum_max)
        end

        it 'will never return zero' do
          expect(base_dummy_class.send(:smooth_factor)).to be > 0.0
        end
      end

      context 'when given an array with infinite elements (pointless case but fun)' do
        before do
          base_dummy_class.instance_variable_set(:@count, Float::INFINITY)
        end

        it 'returns zero' do
          expect(base_dummy_class.send(:smooth_factor)).to eq(0)
        end
      end
    end

    describe 'data' do
      context 'when the scope is nil' do
        it 'returns the data array' do
          expect(base_dummy_class.send(:data, scope: nil)).to eq(base_data_array)
        end
      end

      context 'when the scope is current' do
        it 'returns the last element in the data array' do
          expect(base_dummy_class.send(:data, scope: :current)).to eq(20)
        end
      end

      context 'when the scope is former' do
        it 'returns the second to last element in the data array' do
          expect(base_dummy_class.send(:data, scope: :former)).to eq(19)
        end
      end
    end
  end
end
