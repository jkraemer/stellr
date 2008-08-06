require 'test_helper'

class Stellr::Strategies::Queueing

  # used in test cases to give the queueing thread some time for
  # auto-rotating the indexes
  def wait_for
    sleep 0.1 while !@queue.empty?
    sleep 0.1
  end

end

class ServerTest < StellrTest
  
  def setup
    super
    @server = Stellr::Server.new Stellr::Config.new( nil, :base_dir => INDEX_TMP_TEST_DIR )
  end

  def teardown
    @server.send :shutdown, :abort
    @server = nil
  end

  def test_register_collection_defaults
    c = @server.register 'default'
    assert c
    assert_equal Stellr::Collections::RSync, c.class
  end

  def test_register_static_collection
    c = @server.register 'static', :collection_class => 'Stellr::Collections::Static'
    assert c
    assert_equal Stellr::Collections::Static, c.class
  end

  def test_register_queueing_collection
    c = @server.register 'queue', :strategy_class => 'Stellr::Strategies::Queueing'
    assert c
    assert_equal Stellr::Strategies::Queueing, c.class
  end
  
  def test_default_options
    @server.register 'default'
    config = @server.instance_variable_get "@config"
    assert_equal 9010, config.port
    assert_equal Stellr::Collections::RSync, @server.collection( 'default' ).class
  end
  
  def test_index_data
    @server.register 'default'
    @server.add_record 'default', { :id => 1, :text => 'hello world' }
    @server.add_record 'default', { :id => 2, :text => 'hello world' }
    @server.batch_finished 'default'
    assert_equal 2, @server.size( 'default' )
  end
  
  def test_index_multiple_records_arrays
    @server.register 'default'
    @server.add_records 'default', 
                        [ [ { :id => 1, :text => 'hello world' }, 2],
                          [ { :id => 2, :text => 'hello world two' }, nil ] ]
    @server.batch_finished 'default'
    assert_equal 2, @server.size( 'default' )
  end
  
  def test_index_multiple_records_hashes
    @server.register 'default'
    @server.add_records 'default', 
                        [ { :id => 1, :text => 'hello world' },
                          { :id => 2, :text => 'hello world two' } ]
    @server.batch_finished 'default'
    assert_equal 2, @server.size( 'default' )
  end
  
  def test_delete_data_queued
    coll = "del-queued"
    @server.register coll, :strategy => :queueing
    assert_equal 0, @server.size( coll )
    @server.add_record coll, { :id => 1, :text => 'hello world' }
    @server.add_record coll, { :id => 2, :text => 'hello world' }
    @server.wait_for coll
    assert_equal 2, @server.size( coll )
    @server.delete_record coll, { :id => 2, :text => 'hello world' }
    assert_equal 2, @server.size( coll )
    @server.wait_for coll
    assert_equal 1, @server.size( coll )
  end

  def test_delete_data_blocking
    coll = "del-blocking"
    @server.register coll, :strategy => nil
    assert_equal 0, @server.size( coll )
    @server.add_record coll, { :id => 1, :text => 'hello world' }
    @server.add_record coll, { :id => 2, :text => 'hello world' }
    @server.switch coll
    assert_equal 2, @server.size( coll )
    @server.delete_record coll, { :id => 2, :text => 'hello world' }
    assert_equal 2, @server.size( coll )
    @server.switch coll
    assert_equal 1, @server.size( coll )
  end
  
  def test_data_require_id_field
    @server.register 'default'
    assert_raise ArgumentError do
      @server.add_record 'default', { :text => 'hello world' }
    end
  end
  
end
