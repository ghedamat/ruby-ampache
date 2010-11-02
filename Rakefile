require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "ruby-ampache"
    gem.summary = %Q{Ruby ampache command line client}
    gem.description = %Q{ruby ampache command line client}
    gem.email = "thamayor@gmail.com"
    gem.homepage = "http://github.com/ghedamat/ruby-ampache"
    gem.authors = ["ghedmat"]
    #gem.add_development_dependency "thoughtbot-shoulda", ">= 0"
	gem.files =  FileList["[A-Z]*", "{bin,generators,lib,test}/**/*", ]
	gem.add_dependency 'nokogiri'
	gem.add_dependency 'highline'
	gem.add_dependency 'parseconfig'
	gem.add_dependency 'open4'
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

