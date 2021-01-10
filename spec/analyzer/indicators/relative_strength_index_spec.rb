# frozen_string_literal: true

require_relative '../../../lib/palantir'

describe Palantir::Analyzer::Indicators::RelativeStrengthIndex do
  let(:dummy_data) do
    [
      26.5,
      26.4,
      25.9,
      25.2,
      26.0,
      26.2,
      26.7,
      26.2,
      25.2,
      25.6,
      25.6,
      26.7,
      26.4,
      26.5
    ]
  end
  let(:dummy_class) { described_class.new(input_data: dummy_data) }

  before do
    stub_const('ENV', 'TEST' => 'true')
  end

  describe 'the general API' do
    context 'when supplied an array of more than 14 objects' do
      it 'does not raise error' do
        expect { described_class.new(input_data: dummy_data) }.not_to raise_error
      end
    end

    context 'when supplied an array of less than 14 objects' do
      it 'raises custom error' do
        expect { described_class.new(input_data: []) }
          .to raise_error(
            ::Palantir::Exceptions::IncorrectData,
            'Incorrect data. Expected: Array with at least 14 elements. Got: []',
          )
      end
    end
  end

  describe 'analyze' do
    context 'when supplied with data' do
      before do
        allow(dummy_class).to receive(:rsi_step_one).and_return(90)
        allow(dummy_class).to receive(:rsi_step_two).and_return(89)
      end

      it 'formats the calculated and supplied data' do
        expect(dummy_class.analyze).to eq(
          {
            rsi_step_one: 90,
            rsi_step_two: 89,
            current: 26.5,
            sentiment: :oversold
          },
        )
      end
    end
  end

  describe 'rsi_step_one' do
    context 'when the average_gain is exponentially greater than the average_loss' do
      before do
        allow(dummy_class).to receive(:average).with(type: :gain).and_return(10_000)
        allow(dummy_class).to receive(:average).with(type: :loss).and_return(100)
      end

      it 'returns an extrordinarily strong rsi score' do
        expect(dummy_class.send(:rsi_step_one)).to eq(100)
      end
    end

    context 'when the average_gain is stronger than the average_loss' do
      before do
        allow(dummy_class).to receive(:average).with(type: :gain).and_return(10)
        allow(dummy_class).to receive(:average).with(type: :loss).and_return(1)
      end

      it 'returns a strong rsi score' do
        expect(dummy_class.send(:rsi_step_one)).to eq(91)
      end
    end

    context 'when the average_gain is higher than the average_loss' do
      before do
        allow(dummy_class).to receive(:average).with(type: :gain).and_return(5)
        allow(dummy_class).to receive(:average).with(type: :loss).and_return(1)
      end

      it 'returns a high rsi score' do
        expect(dummy_class.send(:rsi_step_one)).to eq(84)
      end
    end
  end

  describe 'rsi_step_two' do
    context 'when the previous_average_gain is exponentially greater than the previous_average_loss' do
      before do
        allow(dummy_class).to receive(:average).with(type: :gain, scope: :previous).and_return(10_000)
        allow(dummy_class).to receive(:average).with(type: :gain, scope: :current).and_return(1_000)
        allow(dummy_class).to receive(:average).with(type: :loss, scope: :previous).and_return(100)
        allow(dummy_class).to receive(:average).with(type: :loss, scope: :current).and_return(10)
      end

      it 'returns an extrordinarily strong rsi score' do
        expect(dummy_class.send(:rsi_step_two)).to eq(100)
      end
    end
  end

  describe 'average_median_gain' do
    context 'when the ticker is on an absolute uptrend' do
      it 'returns an accurate average median gain percentage' do
        expect(described_class.new(input_data: [1, 10, 19, 28, 37, 46, 55, 64, 73, 82, 91, 100, 109, 118,
                                                127]).send(:average_median_gain).ceil(2)).to eq(15.22)
      end
    end

    context 'when the ticker is on a strong uptrend' do
      it 'returns an accurate average median gain percentage' do
        expect(described_class.new(input_data: [1.01, 1.03, 1.02, 1.04, 1.03, 1.05, 1.04, 1.06, 1.05, 1.07, 1.06,
                                                1.08, 1.07, 1.09])
          .send(:average_median_gain).ceil(2)).to eq(1.87)
      end
    end

    context 'when the ticker is on a strong downtrend' do
      it 'returns float zero' do
        expect(described_class.new(input_data: [16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3])
          .send(:average_median_gain)).to eq(0.0)
      end
    end
  end

  describe 'average_median_loss' do
    context 'when the ticker is on an absolute downtrend' do
      it 'returns an accurate average median loss percentage' do
        expect(described_class.new(input_data: [127, 109, 100, 91, 82, 73, 64, 55, 46, 37, 28, 19, 10,
                                                1]).send(:average_median_loss).ceil(2)).to eq(-14.17)
      end
    end

    context 'when the ticker is on a strong downtrend' do
      it 'returns an accurate average median loss percentage' do
        expect(described_class.new(input_data: [1.09, 1.07, 1.08, 1.06, 1.07, 1.05, 1.06, 1.04, 1.05, 1.03, 1.04,
                                                1.02, 1.03, 1.01])
          .send(:average_median_loss).ceil(2)).to eq(-1.83)
      end
    end

    context 'when the ticker is on an absolute uptrend' do
      it 'returns float zero' do
        expect(described_class.new(input_data: [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
          .send(:average_median_loss)).to eq(0.0)
      end
    end
  end

  describe 'average' do
    context 'when calculating gain' do
      context 'when the ticker is on an absolute uptrend' do
        it 'returns an accurate average gain score, which is average_median_gain / the count of elements' do
          expect(described_class.new(input_data: [1, 10, 19, 28, 37, 46, 55, 64, 73, 82, 91, 100, 109, 118,
                                                  127]).send(:average, type: :gain).ceil(2)).to eq(1.02)
        end
      end
    end
  end

  describe 'data' do
    context 'when the scope is not defined' do
      it 'returns the entire input data' do
        expect(dummy_class.send(:data, scope: nil)).to eq(dummy_data)
      end
    end

    context 'when the scope is defined as current' do
      it 'returns the last two elements of data' do
        expect(dummy_class.send(:data, scope: :current)).to eq([26.4, 26.5])
      end
    end

    context 'when the scope is defined as previous' do
      it 'returns all elements except the last two' do
        expect(dummy_class.send(:data, scope: :previous)).to eq([
                                                                  26.5,
                                                                  26.4,
                                                                  25.9,
                                                                  25.2,
                                                                  26.0,
                                                                  26.2,
                                                                  26.7,
                                                                  26.2,
                                                                  25.2,
                                                                  25.6,
                                                                  25.6,
                                                                  26.7
                                                                ])
      end
    end
  end

  describe 'get_percentage_leap' do
    context 'when the leap is between two floats' do
      context 'when the first leap is higher than the last' do
        it 'returns an accurate percentage leap' do
          expect(dummy_class.send(:get_percentage_leap, 1.01, 1.03).ceil(2)).to eq(1.99)
        end
      end

      context 'when the first leap is lower than the last' do
        it 'returns an accurate percentage leap' do
          expect(dummy_class.send(:get_percentage_leap, 1.03, 1.01).ceil(2)).to eq(-1.94)
        end
      end
    end

    context 'when the leap is between two integers' do
      context 'when the first leap is higher than the last' do
        it 'returns an accurate percentage leap' do
          expect(dummy_class.send(:get_percentage_leap, 100, 120)).to eq(20)
        end
      end

      context 'when the first leap is lower than the last' do
        it 'returns an accurate percentage leap' do
          expect(dummy_class.send(:get_percentage_leap, 100, 80)).to eq(-20)
        end
      end
    end
  end

  describe 'sentiment' do
    context 'when rsi is strong' do
      before do
        allow(dummy_class).to receive(:rsi_step_two).and_return(71)
      end

      it 'returns oversold' do
        expect(dummy_class.send(:sentiment)).to eq(:oversold)
      end
    end

    context 'when rsi is weak' do
      before do
        allow(dummy_class).to receive(:rsi_step_two).and_return(29)
      end

      it 'returns undersold' do
        expect(dummy_class.send(:sentiment)).to eq(:undersold)
      end
    end

    context 'when rsi is neither strong nor weak' do
      before do
        allow(dummy_class).to receive(:rsi_step_two).and_return(50)
      end

      it 'returns neutral' do
        expect(dummy_class.send(:sentiment)).to eq(:neutral)
      end
    end
  end
end
