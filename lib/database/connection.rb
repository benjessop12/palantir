# frozen_string_literal: true

module Palantir
  module Database
    module Connection
      module_function

      def postgresql_connection(config: nil)
        conn_params = config.compact
        valid_conn_param_keys = PG::Connection.conndefaults_hash.keys + [:requiressl]
        updated_params = sanitize_params(conn_params: conn_params, valid_conn_param_keys: valid_conn_param_keys)

        PostgreSQLAdapter.new(
          connection: PostgreSQLAdapter.new_client(conn_params: updated_params),
        )
      end

      def sanitize_params(conn_params: nil, valid_conn_param_keys: nil)
        valid_conn_param_keys.each_with_object({}) do |k, hash|
          hash[k] = conn_params[k] if conn_params.key?(k)
        end
      end

      class PostgreSQLAdapter
        class << self
          def new_client(conn_params: nil)
            PG.connect(conn_params)
          rescue ::PG::Error => e
            raise ::Palantir::Exceptions::NoDatabase.new(logger: ::Palantir.logger, conn_params: conn_params) \
            if conn_params && conn_params[:dbname] && e.message.include?(conn_params[:dbname])

            raise ::Palantir::Exceptions::NoEstablishedConnection.new(logger: ::Palantir.logger,
                                                                      conn_params: conn_params)
          end
        end

        attr_reader :connection, \
                    :conn_params, \
                    :logger,
                    :config

        def initialize(connection: nil)
          @connection = connection
          @logger = ::Palantir.logger
        end

        def execute(sql: nil)
          ::Palantir::Database::ShareLock.new.permit_concurrent_loads do
            result = connection.query sql
            logger.write(time: Time.now, message: sql)
            return result
          end
        end
      end
    end
  end
end
