# frozen_string_literal: true

require 'timecop'

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

  describe 'run_until' do
    context 'when RUN_UNTIl env variable is defined' do
      before do
        ENV['RUN_UNTIL'] = '12:00'
        Timecop.freeze(Time.local(2020))
      end

      after do
        ENV.delete('RUN_UNTIL')
        Timecop.return
      end

      it 'returns the env variable as time' do
        expect(described_class.send(:run_until)).to eq(Time.parse('2020-01-01 12:00'))
      end
    end

    context 'when RUN_UNTIL env variable is not defined' do
      it 'returns infinity' do
        expect(described_class.send(:run_until)).to eq(Float::INFINITY)
      end
    end
  end

  describe 'convert_run_until' do
    context 'when run_until is a valid time' do
      before do
        Timecop.freeze(Time.local(2020))
      end

      after do
        Timecop.return
      end

      it 'parses the string to time' do
        expect(described_class.send(:convert_run_until, run_until: '12:00')).to eq(Time.parse('2020-01-01 12:00'))
      end
    end

    context 'when run_until is not a valid time' do
      it 'returns infinity' do
        expect(described_class.send(:convert_run_until, run_until: 'invalid')).to eq(Float::INFINITY)
      end
    end
  end

  describe 'interval' do
    context 'when the INTERVAL env variable is set' do
      after do
        ENV.delete('INTERVAL')
      end

      context 'when the env variable is valid' do
        before do
          ENV['INTERVAL'] = '2.minutes'
        end

        it 'returns the defined interval in integer seconds as interval' do
          expect(described_class.send(:interval)).to eq(120)
        end
      end

      context 'when the env variable is not valid' do
        before do
          ENV['INTERVAL'] = '1minute'
        end

        it 'returns the BASE_INTERVAL as interval' do
          expect(described_class.send(:interval)).to eq(Palantir::Runner::BASE_INTERVAL)
        end
      end
    end

    context 'when the INTERVAL env variable is not set' do
      it 'returns the BASE_INTERVAL as interval' do
        expect(described_class.send(:interval)).to eq(Palantir::Runner::BASE_INTERVAL)
      end
    end
  end

  describe 'invalid_interval?' do
    context 'when the interval is valid' do
      it 'returns true' do
        expect(described_class.send(:invalid_interval?, interval: '1.minute')).to eq(false)
      end
    end

    context 'when the interval is not valid' do
      context 'due to invalid count' do
        it 'returns true' do
          expect(described_class.send(:invalid_interval?, interval: 'not.minute')).to eq(true)
        end
      end

      context 'due to invalid metric' do
        it 'returns true' do
          expect(described_class.send(:invalid_interval?, interval: '1.secon')).to eq(true)
        end
      end

      context 'due to invalid seperator' do
        it 'returns true' do
          expect(described_class.send(:invalid_interval?, interval: '1second')).to eq(true)
        end
      end
    end
  end

  describe 'convert_interval' do
    context 'when given a valid interval' do
      it 'converts the string to integer seconds' do
        expect(described_class.send(:convert_interval, interval: '2.minutes')).to eq(120)
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
