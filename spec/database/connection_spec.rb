# frozen_string_literal: true

require_relative '../../lib/palantir'

class StubClass
  class << self
    def query(sql)
    end
  end
end

describe Palantir::Database::Connection do
  before do
    stub_const('ENV', 'TEST' => 'true')
  end

  describe 'postgresql_connection' do
    context 'when given a config' do
      before do
        allow(::Palantir::Database::Connection::PostgreSQLAdapter).to receive(:new_client)
        allow(::Palantir::Database::Connection::PostgreSQLAdapter).to receive(:new)
      end

      it 'initializes an instance of postgresql adapter' do
        described_class.postgresql_connection(config: { host: 'somehost' })
        expect(::Palantir::Database::Connection::PostgreSQLAdapter).to have_received(:new)
      end
    end
  end

  describe 'sanitize_params' do
    context 'when given a hash that has keys that are both in / not in the comparison array' do
      let(:conn_params) { { password: 'pg_key', not_a_valid_key: 'should be removed' } }
      let(:valid_conn_param_keys) { [:password] }
      let(:expected_output) { { password: 'pg_key' } }

      it 'removes the invalid keys that are not in the comparison array' do
        expect(described_class.sanitize_params(conn_params: conn_params, valid_conn_param_keys: valid_conn_param_keys))
          .to eq(expected_output)
      end
    end
  end

  describe Palantir::Database::Connection::PostgreSQLAdapter do
    describe 'new_client' do
      context 'when there is no database' do
        let(:conn_params) { { dbname: 'database_name' } }

        before do
          allow(PG).to receive(:connect).and_raise(PG::Error.new(/database_name/))
        end

        it 'raises custom no database error' do
          expect { described_class.new_client(conn_params: conn_params) }
            .to raise_error(Palantir::Exceptions::NoDatabase)
        end
      end

      context 'when there is no established connection' do
        before do
          allow(PG).to receive(:connect).and_raise(PG::Error)
        end

        it 'raises custom no established connection error' do
          expect { described_class.new_client }
            .to raise_error(Palantir::Exceptions::NoEstablishedConnection)
        end
      end
    end

    describe 'execute' do
      context 'with valid connection' do
        let(:postgresql_connection) { Palantir::Database::Connection::PostgreSQLAdapter.new_client }
        let(:with_valid_connection) { described_class.new(connection: postgresql_connection) }

        before do
          allow(Palantir::Database::ShareLock).to receive(:permit_concurrent_loads)
          allow(described_class).to receive(:new_client).and_return(StubClass)
        end

        it 'does not raise an error' do
          expect { with_valid_connection.execute(sql: 'some sql') }.not_to raise_error
        end
      end
    end
  end
end
