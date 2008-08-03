require 'test/unit'
require 'stellr'
require 'fileutils'
require 'test_helper'

class StellrTest < Test::Unit::TestCase
  INDEX_TMP_TEST_DIR = "/tmp/stellr/test"

  @@data = {}

  def setup
    FileUtils.rm_rf INDEX_TMP_TEST_DIR
  end
  
  def teardown
  end
  
  def test_truth
    assert true
  end
  
  def self.fixtures( fixture_name )
    file_name = File.join( File.dirname(__FILE__), "/fixtures/#{fixture_name}.yml" )
    @@data[fixture_name] = YAML.load( IO.read( file_name ) )
    define_method( fixture_name.to_sym ) do |key|
      @@data[fixture_name][key.to_s].symbolize_keys
    end
  end
end

class Hash
  def symbolize_keys
    inject({}) do |options, (key, value)|
      options[key.to_sym] = value
      options
    end
  end
end