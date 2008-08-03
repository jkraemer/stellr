module SimpleCollectionTests
  def test_index
    assert_equal 0, @collection.size
    index_something
    assert_equal 0, @collection.size
    @collection.switch
    assert_equal 2, @collection.size
  end

  def test_search_empty_collection
    results = @collection.search 'cabinet'
    assert_equal 0, results.total_hits
    assert results.empty?
    index_something
    # not switched, so still no results
    results = @collection.search 'cabinet'
    assert_equal 0, results.total_hits
    assert results.empty?
  end

  def test_search
    index_something
    @collection.switch
    results = @collection.search 'cabinet'
    assert_equal 2, results.total_hits
    assert results.find {|r| r[:id] == '1'}
    assert results.find {|r| r[:id] == '2'}
    assert_nil results.first[:title]

    results = @collection.search 'cabinet', :get_fields => [ :title ]
    assert_equal 2, results.total_hits
    assert results.find {|r| r[:id] == '1'}
    assert results.find {|r| r[:id] == '2'}
    assert_equal movies(:caligari)[:title], results.first[:title]
  end

  def test_delete
    @collection << { :id => 1, :title => movies(:caligari)[:title] }
    @collection.switch
    assert_equal 1, @collection.size
    @collection.delete_record  :id => 1 
    assert_equal 1, @collection.size
    @collection.switch
    assert_equal 0, @collection.size
    @collection.switch
    assert_equal 0, @collection.size
  end

  def test_data_requires_id_field
    assert_raise ArgumentError do
      @collection.add_record :text => 'hello world'
    end
  end

  protected
  
  def index_something
    @collection << { :id => 1, :title => movies(:caligari)[:title] }
    @collection << { :id => 1, :title => movies(:caligari)[:title] }
    @collection << { :id => 2, :title => movies(:caligari)[:title] }
  end
  

end
