# frozen_string_literal: true

desc 'Running the analyzer'
namespace :palantir do
  task :run do
    ::Palantir::Runner.run!
  end
end
