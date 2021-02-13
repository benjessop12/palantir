# frozen_string_literal: true

require 'yaml'

desc 'Setting up ticker file'
namespace :palantir do
  task :setup do
    stable_stocks = %w[
      SPY
      TSLA
    ]
    write_to_file ::Palantir::TICKER_CONFIG_FILE, stable_stocks.to_yaml
    ::Palantir::Models::Variables.new.migrate(environment: 'test')
    ::Palantir::Models::Variables.new.migrate(environment: 'production')
    ::Palantir::Models::Reports.new.migrate(environment: 'test')
    ::Palantir::Models::Reports.new.migrate(environment: 'production')
  end

  task :clear_db do
    ::Palantir::Models::Variables.new.clear(environment: 'test')
    ::Palantir::Models::Variables.new.clear(environment: 'production')
    ::Palantir::Models::Reports.new.clear(environment: 'test')
    ::Palantir::Models::Reports.new.clear(environment: 'production')
  end

  task :setup_email do
    write_to_file(
      ::Palantir::EMAIL_CONFIG_FILE,
      email_body(ENV['EMAIL'], ENV['PASSWORD']),
    )
  end
end

def query(sql: nil)
  ::Palantir::Database.query(sql: sql)
end

def email_body(email, password)
  <<~SSMTP_CONFIG
    root=postmaster
    mailhub=smtp.gmail.com
    hostname=palantir
    AuthUser=#{email}
    AuthPass=#{password}
    FromLineOverride=YES
    UseSTARTTLS=YES
  SSMTP_CONFIG
end

def write_to_file(file_path, body)
  File.open(file_path, 'w') { |file| file.write(body) }
end
