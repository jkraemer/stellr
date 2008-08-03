require 'drb'
require 'stellr/search'

module Stellr

  # = Stellr client
  #
  # This class acts as a wrapper around the connection to a Stellr server.
  # Typical usage looks like this:
  #
  #    stellr = Stellr::Client.new('druby://myserver.com:9000')
  #    collection = stellr.connect('myindex', :fields => { :content => { :store => :yes } })
  #    collection << { :content => 'lorem ipsum' }
  #    results = collection.search('lorem', :page => 1, :per_page => 10)
  #
  class Client

    def initialize( drb_uri )
      @server = DRbObject.new(nil, drb_uri)
    end

    # connects to a remote collection and returns a stub that can be used to
    # add records to the collection and to search for them.
    def connect( collection_name, collection_args = nil )
      @server.register collection_name, collection_args
      ClientCollection.new @server, collection_name
    end

    # Connects to multiple remote collections at once. This allows to run
    # searches across multiple physical collections.
    def multi_connect( collection_names, options = {} )
      MultiCollection.new @server, collection_names, options
    end

  end

  # Wrapper around a remote collection.
  #
  # See the documentation of the collection class you use for more information.
  class ClientCollection

    def initialize( server, name )
      @name   = name
      @server = server
    end

    # Disconnects this collection from the server.
    def disconnect
      @server = nil
    end

    def method_missing( method, *args )
      raise "use of disconnected collection" if @server.nil?
      @server.send method, @name, *args
    end

  end

  # This client collection class allows to search multiple server side
  # collections at once.
  class MultiCollection < ClientCollection
    def initialize( server, names, options = {} )
      @server = server
      @name = @server.register_multi_collection names, options
    end
  end

end

