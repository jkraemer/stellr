require 'test_helper'

class CollectionsBaseTest < StellrTest
  
  def test_create_without_strategy
    %w( Static RSync ).each do |coll_class|
      c = Stellr::Collections::Base.create('test', :collection_class => "Stellr::Collections::#{coll_class}",
                                                   :path             => INDEX_TMP_TEST_DIR )
      assert c.class.name =~ /#{coll_class}$/
      c.close
    end
  end

  def test_create_with_strategy
    %w( Static RSync ).each do |coll_class|
      %w( Queueing Blocking ).each do |strategy_class|
        c = Stellr::Collections::Base.create('test', :collection_class => "Stellr::Collections::#{coll_class}",
                                                     :strategy_class   => "Stellr::Strategies::#{strategy_class}",
                                                     :path             => INDEX_TMP_TEST_DIR )
        assert c.class.name =~ /#{strategy_class}$/
        c.close
      end
    end
  end
end
