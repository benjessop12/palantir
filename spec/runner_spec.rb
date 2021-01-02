# frozen_string_literal: true

require_relative '../lib/palantir'

describe Palantir::Runner do
  before do
    stub_const('Palantir::TICKER_CONFIG_FILE', 'config/ticker_config.yml.test')
  end

  describe 'run!' do
    context 'when tickers are defined' do
      before do
        allow(described_class).to receive(:defined_tickers?).and_return(true)
      end

      it 'does not raise an error' do
        expect { described_class.run! }.not_to raise_error
      end
    end

    context 'when tickers are not defined' do
      it 'raises an error' do
        expect do
          described_class.run!
        end.to raise_error(Palantir::Exceptions::NoTickers,
                           /No tickers defined for the cycle. You must define a ticker as per the instructions/)
      end
    end
  end

  describe 'collect_tickers' do
    before do
      allow(described_class).to receive(:tickers_from_env).and_return(%w[PLTR])
    end

    context 'when both methods return array' do
      before do
        allow(described_class).to receive(:tickers_from_config).and_return(%w[NIO])
      end

      it 'returns elements from both methods' do
        expect(described_class.send(:collect_tickers)).to eq(%w[PLTR NIO])
      end
    end

    context 'when only tickers_from_env return array' do
      it 'returns only elements from tickers_from_env' do
        expect(described_class.send(:collect_tickers)).to eq(['PLTR'])
      end
    end
  end

  describe 'concurrency' do
    after do
      ENV.delete('CONCURRENCY')
    end

    context 'when the CONCURRENCY env variable is set' do
      before do
        ENV['CONCURRENCY'] = '7'
      end

      it 'equals the concurrency that is passed' do
        expect(described_class.send(:concurrency)).to eq(7)
      end
    end

    context 'when the CONCURRENCY env variable is not set' do
      it 'equals the default concurrency sizing' do
        expect(described_class.send(:concurrency)).to eq(5)
      end
    end
  end

  describe 'defined_tickers?' do
    context 'when one of the env defs returns tickers' do
      before do
        allow(described_class).to receive(:tickers_from_env).and_return(%w[PLTR NIO])
      end

      it 'returns true' do
        expect(described_class.send(:defined_tickers?)).to eq(true)
      end
    end

    context 'when none of the env defs return tickers' do
      it 'returns false' do
        expect(described_class.send(:defined_tickers?)).to eq(false)
      end
    end
  end

  describe 'tickers_from_env' do
    context 'when the TICKERS env variable is defined' do
      before do
        ENV['TICKERS'] = 'PLTR,NIO'
      end

      after do
        ENV.delete('TICKERS')
      end

      it 'splits the tickers by comma' do
        expect(described_class.send(:tickers_from_env)).to eq(%w[PLTR NIO])
      end
    end

    context 'when the TICKERS env variable is not defined' do
      it 'returns an empty array' do
        expect(described_class.send(:tickers_from_env)).to eq([])
      end
    end
  end

  describe 'run_wild' do
    context 'when the RUN_WILD env variable is defined' do
      after do
        ENV.delete('RUN_WILD')
      end

      context 'as true' do
        before do
          ENV['RUN_WILD'] = 'true'
        end

        it 'returns true' do
          expect(described_class.send(:run_wild)).to eq(true)
        end
      end

      context 'as TRUE' do
        before do
          ENV['RUN_WILD'] = 'TRUE'
        end

        it 'returns true' do
          expect(described_class.send(:run_wild)).to eq(true)
        end
      end

      context 'as false' do
        before do
          ENV['RUN_WILD'] = 'false'
        end

        it 'returns false' do
          expect(described_class.send(:run_wild)).to eq(false)
        end
      end
    end

    context 'when the RUN_WILD env variable is not defined' do
      it 'returns false' do
        expect(described_class.send(:run_wild)).to eq(false)
      end
    end
  end

  describe 'rumour_ratio' do
    context 'when the RUMOUR env variable is defined' do
      after do
        ENV.delete('RUMOUR')
      end

      context 'as a string' do
        context 'that can be parsed to a float' do
          before do
            ENV['RUMOUR'] = '0.9'
          end

          it 'does not raise error' do
            expect(described_class.send(:rumour_ratio)).to eq(0.9)
          end
        end

        context 'that can not be parsed to a float' do
          before do
            ENV['RUMOUR'] = 'not_a_float'
          end

          it 'raises an error' do
            expect { described_class.send(:rumour_ratio) }
              .to raise_error(
                ::Palantir::Exceptions::IncorrectRumour,
                /Rumour must be a float and less than 1. Attempted to pass not_a_float as the rumour/,
              )
          end
        end
      end
    end

    context 'when the RUMOUR env variable is not defined' do
      it 'returns 0' do
        expect(described_class.send(:rumour_ratio)).to eq(nil)
      end
    end
  end

  describe 'valid_float?' do
    context 'when the ENV variable is set' do
      after do
        ENV.delete('RUMOUR')
      end

      context 'when the float is valid' do
        before do
          ENV['RUMOUR'] = '0.9'
        end

        it 'returns true' do
          expect(described_class.send(:valid_float?)).to eq(true)
        end
      end

      context 'when the float is invalid' do
        before do
          ENV['RUMOUR'] = 'not_a_float'
        end

        it 'returns false' do
          expect(described_class.send(:valid_float?)).to eq(false)
        end
      end
    end

    context 'when the ENV variable is not set' do
      it 'returns false' do
        expect(described_class.send(:valid_float?)).to eq(false)
      end
    end
  end
end
