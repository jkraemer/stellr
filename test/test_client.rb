require 'test_helper'
require 'simple_collection_tests'

require 'stellr/client'

class ClientTest < StellrTest
  include SimpleCollectionTests
  fixtures :movies
  
  DRB_URI = "druby://localhost:99999"
  def setup
    super
    @server_obj = Stellr::Server.new Stellr::Config.new( nil, :base_dir => INDEX_TMP_TEST_DIR )
    @server = DRb.start_service DRB_URI, @server_obj

    @client = Stellr::Client.new DRB_URI
    @collection = @client.connect 'default', :collection => :static, :fields => { :title => {}}
  end

  def teardown
    @server_obj.send :shutdown, :abort
    @server.stop_service
    @server.thread.join
  end
  
  
end
