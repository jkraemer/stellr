require 'rubygems'
require 'hoe'
$:.unshift 'lib'
require './lib/stellr.rb'

class Hoe
  def extra_deps
    @extra_deps.reject do |x|
      Array(x).first == 'hoe'
    end
  end
end

Hoe.new('stellr', Stellr::VERSION) do |p|
  p.rubyforge_name = 'stellr'
  p.author = [ 'Benjamin Krause', 'Jens Krämer' ]
  p.email = [ 'bk@benjaminkrause.com', 'jk@jkraemer.net' ]
  p.summary = 'Stellr is a Ferret based standalone search server.'
  p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.extra_deps << [ 'ferret', '>= 0.11.6', 'daemons', '>= 1.0.10', 'fastthread', '>= 1.0' ]
end

desc "Release and publish documentation"
task :repubdoc => [:release, :publish_docs]

# vim:syntax=ruby
