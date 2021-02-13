# frozen_string_literal: true

require_relative '../../lib/palantir'

class StubModel < Palantir::Models::Base
  ATTRIBUTES = %w[stub_attribute_one stub_attribute_two].freeze

  def initialize
    super(table: 'reports')
  end
end

class StubColumns
  class << self
    def are?(attributes: nil)
      column_names == attributes
    end

    private

    def column_names
      %i[stub_attribute_one stub_attribute_two]
    end
  end
end

describe Palantir::Models::Base do
  let(:described_instance) { StubModel.new }
  let(:mapped_attributes) { %w[stub_attribute_one stub_attribute_two] }

  describe 'attributes' do
    context 'when the table exists' do
      before do
        allow(described_instance).to receive(:table_exists?).and_return(true)
        allow(described_instance).to receive(:column_names).and_return(StubColumns)
        allow(described_instance).to receive(:inherited_attributes).and_return(mapped_attributes)
      end

      context 'and the columns are mapped correctly' do
        before do
          allow(StubColumns).to receive(:are?).and_return(true)
        end

        it 'returns the inherited attributes' do
          expect(described_instance.attributes).to eq(mapped_attributes)
        end
      end

      context 'and the columns are not mapped correctly' do
        before do
          allow(StubColumns).to receive(:are?).and_return(false)
        end

        it 'raises an database sync error' do
          expect { described_instance.attributes }.to raise_error(
            ::Palantir::Exceptions::DatabaseIntegrityError,
            /Your database is out of sync with your models. Please re-run migrations./,
          )
        end
      end
    end

    context 'when the table does not exist' do
      before do
        allow(described_instance).to receive(:table_exists?).and_return(false)
      end

      it 'raises an database table does not exist error' do
        expect { described_instance.attributes }.to raise_error(
          ::Palantir::Exceptions::DatabaseIntegrityError,
          /Table does not exist. Please run your migrations./,
        )
      end
    end
  end

  describe 'migrate' do
    context 'when the table exists' do
      before do
        allow(described_instance).to receive(:table_exists?).and_return(true)
      end

      it 'raises an database migration has been run error' do
        expect { described_instance.migrate }.to raise_error(
          ::Palantir::Exceptions::DatabaseIntegrityError,
          /Your migration has been run./,
        )
      end
    end

    context 'when the table does not exist' do
      before do
        allow(described_instance).to receive(:table_exists?).and_return(false)
        allow(::Palantir::Database).to receive(:query)
      end

      it 'runs the migration, creating a table with attributes defined in the ATTRIBUTES constant' do
        described_instance.migrate(environment: 'test')
        expect(::Palantir::Database).to have_received(:query).with(
          sql: 'CREATE TABLE IF NOT EXISTS reports_test ' \
               '(stub_attribute_one varchar, stub_attribute_two varchar)',
        )
      end
    end
  end

  describe 'clear' do
    context 'when the table exists' do
      before do
        allow(described_instance).to receive(:table_exists?).and_return(true)
        allow(::Palantir::Database).to receive(:query)
      end

      it 'clears the database table' do
        described_instance.clear(environment: 'test')
        expect(::Palantir::Database).to have_received(:query).with(
          sql: 'DELETE FROM reports_test',
        )
      end
    end

    context 'when the table does not exist' do
      before do
        allow(described_instance).to receive(:table_exists?).and_return(false)
      end

      it 'raises a cannot clear table as it does not exist error' do
        expect { described_instance.clear(environment: 'test') }.to raise_error(
          ::Palantir::Exceptions::DatabaseIntegrityError,
          /You cannot clear this table as it does not exist./,
        )
      end
    end
  end

  describe 'save' do
    context 'when saving a hash' do
      context 'when the keys are valid columns' do
        let(:valid_data) do
          {
            stub_attribute_one: 'stub_value_one',
            stub_attribute_two: 'stub_value_two'
          }
        end

        before do
          allow(described_instance).to receive(:column_names).and_return(StubColumns)
          allow(StubColumns).to receive(:query)
            .and_return(%s(stub_value_one stub_value_two))
          allow(::Palantir::Database).to receive(:query).and_return(true)
        end

        it 'generates sql for saving' do
          described_instance.save(data: valid_data, environment: 'test')
          expect(::Palantir::Database).to have_received(:query).with(
            sql: 'INSERT INTO reports_test (stub_attribute_one, stub_attribute_two) ' \
                  "VALUES ('stub_value_one', 'stub_value_two')",
          )
        end
      end

      context 'when the keys are not valid columns' do
        let(:invalid_data) do
          {
            stub_attribute_one: 'stub_value_one'
          }
        end

        before do
          allow(StubColumns).to receive(:column_names)
            .and_return(%s(not_a_column_in_the_hash))
        end

        it 'raises an error about saving mis-matched column data' do
          expect { described_instance.save(data: invalid_data, environment: 'test') }
            .to raise_error(
              ::Palantir::Exceptions::DatabaseIntegrityError,
              /You have tried inserting keys that do not exist in the table./,
            )
        end
      end
    end

    context 'when saving a non-hash' do
      it 'returns nil' do
        expect(described_instance.save(data: [])).to eq(nil)
      end
    end
  end

  describe 'select' do
    context 'when selecting by values that are an array' do
      let(:values) { %w[test_value_one test_value_two] }
      let(:selector) { 'selector' }
      let(:environment) { 'test' }

      context 'when selecting by valid column name' do
        let(:selector_column) { 'selector_column' }
        let(:expected_result) do
          {
            sql: "SELECT test_value_one, test_value_two FROM reports_test WHERE selector_column = 'selector'",
            values: true
          }
        end

        before do
          allow(::Palantir::Database).to receive(:query).and_return([{ key_one: 'selector_column' }])
        end

        it 'generates valid sql' do
          described_instance.select(values: values, selector_column: selector_column, selector: selector,
                                    environment: environment)
          expect(::Palantir::Database).to have_received(:query).with(expected_result)
        end
      end

      context 'when selecting by invalid column name' do
        let(:selector_column) { 'invalid_selector_column' }

        before do
          allow(::Palantir::Database).to receive(:query).and_return([{ key_one: 'invalid_column_one' }])
        end

        it 'raises integrity error that column selector is not a column in the database' do
          expect do
            described_instance.select(values: values, selector_column: selector_column, selector: selector,
                                      environment: environment)
          end
            .to raise_error(
              ::Palantir::Exceptions::DatabaseIntegrityError,
              /You have tried selecting keys that do not exist in the table./,
            )
        end
      end
    end

    context 'when selecting by values that are not an array' do
      it 'returns nil' do
        expect(described_instance.select(values: {})).to eq(nil)
      end
    end
  end
end
