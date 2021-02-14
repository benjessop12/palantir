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
            sentiment: :overbought
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
        expect(dummy_class.send(:rsi_step_one)).to eq(99.00990099009901)
      end
    end

    context 'when the average_gain is stronger than the average_loss' do
      before do
        allow(dummy_class).to receive(:average).with(type: :gain).and_return(10)
        allow(dummy_class).to receive(:average).with(type: :loss).and_return(1)
      end

      it 'returns a strong rsi score' do
        expect(dummy_class.send(:rsi_step_one)).to eq(90.9090909090909)
      end
    end

    context 'when the average_gain is higher than the average_loss' do
      before do
        allow(dummy_class).to receive(:average).with(type: :gain).and_return(5)
        allow(dummy_class).to receive(:average).with(type: :loss).and_return(1)
      end

      it 'returns a high rsi score' do
        expect(dummy_class.send(:rsi_step_one)).to eq(83.33333333333333)
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
        expect(dummy_class.send(:rsi_step_two)).to eq(99.00990099009901)
      end
    end
  end

  describe 'average' do
    context 'when calculating gain' do
      context 'when the ticker is on an absolute uptrend' do
        it 'returns an accurate average gain score, which is average_median_gain / the count of elements' do
          expect(described_class.new(input_data: [1, 10, 19, 28, 37, 46, 55, 64, 73, 82, 91, 100, 109, 118,
                                                  127]).send(:average, type: :gain).ceil(2)).to eq(9.0)
        end
      end
    end
  end

  describe 'data' do
    context 'when the scope is not defined' do
      it 'returns the entire input data' do
        expect(dummy_class.send(:data, scope: nil, array: dummy_data)).to eq(dummy_data)
      end
    end

    context 'when the scope is defined as current' do
      it 'returns the last two elements of data' do
        expect(dummy_class.send(:data, scope: :current, array: dummy_data)).to eq([26.4, 26.5])
      end
    end

    context 'when the scope is defined as previous' do
      it 'returns all elements except the last two' do
        expect(dummy_class.send(:data, scope: :previous, array: dummy_data)).to eq([
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

  describe 'sentiment' do
    context 'when rsi is strong' do
      before do
        allow(dummy_class).to receive(:rsi_step_two).and_return(71)
      end

      it 'returns overbought' do
        expect(dummy_class.send(:sentiment)).to eq(:overbought)
      end
    end

    context 'when rsi is weak' do
      before do
        allow(dummy_class).to receive(:rsi_step_two).and_return(29)
      end

      it 'returns oversold' do
        expect(dummy_class.send(:sentiment)).to eq(:oversold)
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
