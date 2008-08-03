require 'test_helper'
require 'simple_collection_tests'

class StaticCollectionTest < StellrTest
  include SimpleCollectionTests
  fixtures :movies
  
  def setup
    super
    @collection = Stellr::Collections::Static.new( 'default', default_collection_options )
  end
  
  def test_create
    c = Stellr::Collections::Base.create( 'test', default_collection_options(:collection_class => 'Stellr::Collections::Static') )
    assert_equal Stellr::Collections::Static, c.class
    c.close
    c = Stellr::Collections::Base.create( 'test', default_collection_options(:collection => :static) )
    assert_equal Stellr::Collections::Static, c.class
  end

  def test_switch
    #assert_equal 0, @collection.size
    index_something
    assert_equal 0, @collection.size
    @collection.switch
    assert_equal 2, @collection.size
    
    # switchen ohne vorheriges indizieren leert index
    @collection.switch
    assert_equal 0, @collection.size
    @collection.switch
    assert_equal 0, @collection.size
  end
  
  protected

  def default_collection_options( options = {} )
    { :path     => INDEX_TMP_TEST_DIR, :logger => Logger.new('/tmp/stellr/test.log') }.update( options )
  end
end
