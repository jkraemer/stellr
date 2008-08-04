stellr
    by Jens Kraemer and Benjamin Krause
    http://stellr.rubyforge.org/

== DESCRIPTION:
  
Stellr is a Ferret based standalone search server featuring a DRB and (soon to come) an http frontend. It can handle multiple indexes, including multi-index searches. A client library and a simple command line query tool are included with the gem.

== FEATURES:

* DRb frontend
* easy to use client library (see below)
* multi index search
* Index rotation
  Stellr always keeps two versions of your index around - one is used in a
  multi threaded, read only way to handle incoming search requests, while the
  other one is written to when you index something.
  Using the switch function you may decide when to switch over searching from 
  the old index to the new one. Then, changes will be synced, and searches will
  see the new or updated data from before the switch call.
* Index synchronization
  Two kinds of synchronization methods are supported for now: rsync, using rsync
  two copy over the changes from one index to the other, and static, which will
  completely replace the old index with the new one. While the latter is suitable
  for indexes which you rebuild completely from time to time, the former is good
  for large indexes that are updated frequently or that are too large for frequent
  rebuilds.

== SYNOPSIS:

* start the server:

  stellr -c /path/to/config.yml start

* index something

  require 'stellr/client'
  stellr = Stellr::Client.new('druby://localhost:9010')
  config = {
    :collection => :static,         # static collections are rebuilt from scratch everytime changes occur
    # :collection => :rsync,        # use the rsync collection for indexes that are updated frequently and/or are 
                                    # too large to be rebuilt from scratch every time they're updated
    :analyzer => 'My::Analyzer',
    :fields => {
      :title   => { :boost => 5, :store => :yes },
      :content => { :store => :no }
    }
  }
  collection = stellr.connect('my_collection', config)
  collection.add_record(:id => 1, :title => 'Some Title', :content => 'Content')
  collection.switch # 

* command line search

  stellr-search my_collection 'query string'

  for now, this will display the first 10 hits only.

* search via the client library

  require 'stellr/client'
  stellr = Stellr::Client.new('druby://localhost:9010')
  collection = stellr.connect 'my_collection',
                              :analyzer => 'My::Analyzer'     # the analyzer to use for query parsing
  results = collection.search 'querystring',
                              :page => 1, :per_page => 100,   # built in pagination support
                              :fields => [:title, :content],  # the fields to search in
                              :get_fields => [ :title ]       # the fields to fetch for result display

* multi-collection search
  pass an array of collection names to search multiple
  collections at once:

  collection = stellr.connect [ 'my_collection', 'another_collection' ],
                              :analyzer => 'My::Analyzer'

== REQUIREMENTS:

* Ferret (gem install ferret)
* daemons (gem install daemons)

== INSTALL:

* sudo gem install stellr

== LICENSE:

(The MIT License)

Copyright (c) 2007 FIX

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
