# frozen_string_literal: true

require 'spec_helper'

describe Que::Migrations do
  it "should be able to perform migrations up and down" do
    # Migration #1 creates the table with a priority default of 1, migration
    # #2 ups that to 100.

    default = proc do
      result = Que.execute <<-SQL
        select adsrc::integer
        from pg_attribute a
        join pg_class c on c.oid = a.attrelid
        join pg_attrdef on adrelid = attrelid AND adnum = attnum
        where relname = 'que_jobs'
        and attname = 'priority'
      SQL

      result.first[:adsrc]
    end

    assert_equal 100, default.call
    Que::Migrations.migrate! version: 1
    assert_equal 1, default.call
    Que::Migrations.migrate! version: 2
    assert_equal 100, default.call

    # Clean up.
    Que.migrate!
  end

  it "should be able to get and set the current schema version" do
    assert_equal Que::Migrations::CURRENT_VERSION, Que::Migrations.db_version
    Que::Migrations.set_db_version(59328)
    assert_equal 59328, Que::Migrations.db_version
    Que::Migrations.set_db_version(Que::Migrations::CURRENT_VERSION)
    assert_equal Que::Migrations::CURRENT_VERSION, Que::Migrations.db_version
  end

  it "should be able to cycle the jobs table all the way between nonexistent and current without error" do
    assert_equal Que::Migrations::CURRENT_VERSION, Que::Migrations.db_version
    Que::Migrations.migrate! version: 0
    assert_equal 0, Que::Migrations.db_version
    assert_equal 0, Que.db_version
    Que::Migrations.migrate!
    assert_equal Que::Migrations::CURRENT_VERSION, Que::Migrations.db_version

    # The helper on the Que module does the same thing.
    Que.migrate! version: 0
    assert_equal 0, Que::Migrations.db_version
    Que.migrate!
    assert_equal Que::Migrations::CURRENT_VERSION, Que::Migrations.db_version
  end

  it "should be able to honor the original behavior of Que.drop!" do
    assert DB.table_exists?(:que_jobs)
    Que.drop!
    refute DB.table_exists?(:que_jobs)

    # Clean up.
    Que::Migrations.migrate!
    assert DB.table_exists?(:que_jobs)
  end

  it "should be able to recognize a que_jobs table created before the versioning system" do
    Que.migrate! version: 0
    DB.create_table(:que_jobs){serial :id} # Dummy Table.
    assert_equal 1, Que::Migrations.db_version
    DB.drop_table(:que_jobs)
    Que.migrate!
  end

  it "should be able to honor the original behavior of Que.create!" do
    Que.migrate! version: 0
    Que.create!
    assert DB.table_exists?(:que_jobs)
    assert_equal 1, Que::Migrations.db_version

    # Clean up.
    Que::Migrations.migrate!
    assert DB.table_exists?(:que_jobs)
  end
end
