# frozen_string_literal: true

Dir.glob('./lib/logger/*.rb').sort.each { |file| require file }

module Palantir
  class Logger
    attr_reader :file_path
    attr_accessor :logger_file

    def initialize(file_path: nil)
      @file_path = file_path
      @logger_file = nil
    end

    def write(time: nil, message: nil)
      handle_file do
        formatted_message = Formatter.call(time: time, message: message)
        logger_file.write formatted_message
      end
    end

    private

    def handle_file(&block)
      open_logfile
      block.call
    rescue Errno::ENOENT
      create_logfile
    ensure
      @logger_file&.close
    end

    def create_logfile
      begin
        logfile = File.open(file_path, (File::WRONLY | File::APPEND | File::CREAT | File::EXCL))
        logfile.flock File::LOCK_EX
        logfile.sync = true
        logfile.flock File::LOCK_UN
      rescue Errno::EEXIST
        logfile = open_logfile(file_path)
        logfile.sync = true
      end
      @logger_file = logfile
    end

    def open_logfile
      @logger_file = File.open(file_path, (File::WRONLY | File::APPEND))
    rescue Errno::ENOENT
      create_logfile
    end
  end
end
