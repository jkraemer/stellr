require 'rubygems'
require 'thread'
begin
  require 'fastthread' 
rescue LoadError
  puts "couldn't load fastthread"
end
require 'drb'
require 'monitor'
require 'ferret'
require 'stellr/utils'
require 'stellr/server'
require 'stellr/config'
require 'stellr/collections'
require 'stellr/strategies'
require 'stellr/search'

$SAFE = 1

module Stellr
  VERSION = '0.1.2'
  
  def self.start_server( config )
    if config.script
      begin
        load config.script
      rescue Exception => e
        puts "\nerror loading script #{config.script}: #{e}\n#{e.backtrace.join("\n")}"
        exit 1
      end
    end
    stellr = Server.new config
    server = DRb.start_service config.drb_uri, stellr
    server.thread.join
  end
  
end
