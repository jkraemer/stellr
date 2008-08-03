require 'test_helper'

class RSyncCollectionTest < StellrTest
  fixtures :movies
  
  def setup
    super
    @collection = Stellr::Collections::RSync.new( 'default', default_collection_options )
  end

  def teardown
    super
    @collection.close
  end

  def test_create
    c = Stellr::Collections::Base.create('test', default_collection_options(:collection => :rsync))
    assert_equal Stellr::Collections::RSync, c.class
    c.close
  end

  def test_create_index
    assert_equal Ferret::Index::IndexWriter, @collection.send(:writer).class
  end
  
  def test_create_index_directories
    @collection.send(:writer)
    assert File.directory?( File.join( INDEX_TMP_TEST_DIR, '0' ) )
    assert File.directory?( File.join( INDEX_TMP_TEST_DIR, '1' ) )
    assert File.symlink?(   File.join( INDEX_TMP_TEST_DIR, 'searching' ) )
    assert File.symlink?(   File.join( INDEX_TMP_TEST_DIR, 'indexing' ) )
  end
  
  def test_switch_index
    @collection.send(:writer)
    assert File.symlink?( File.join( INDEX_TMP_TEST_DIR, 'indexing') )
    target = File.readlink( File.join( INDEX_TMP_TEST_DIR, 'indexing') )
    @collection.switch
    assert_equal target, File.readlink( File.join( INDEX_TMP_TEST_DIR, 'searching') )
  end
  
  def test_index
    assert_equal 0, @collection.size
    @collection << { :id => 1, :title => movies(:caligari)[:title] }
    @collection << { :id => 1, :title => movies(:caligari)[:title] }
    @collection << { :id => 2, :title => movies(:caligari)[:title] }
    assert_equal 0, @collection.size
    @collection.switch
    assert_equal 2, @collection.size
    @collection.switch
    assert_equal 2, @collection.size
  end
  
  def test_delete
    @collection << { :id => 1, :title => movies(:caligari)[:title] }
    @collection << { :id => 2, :title => movies(:caligari)[:title] }
    @collection.switch
    assert_equal 2, @collection.size
    @collection.delete_record  :id => 1 
    assert_equal 2, @collection.size
    @collection.switch
    assert_equal 1, @collection.size
    @collection.switch
    assert_equal 1, @collection.size
  end
  
  def default_collection_options( options = {} )
    { :recreate => false,
      :path     => INDEX_TMP_TEST_DIR }.update( options )
  end
end
