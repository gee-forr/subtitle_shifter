require 'rubygems'
require 'rake'
require 'jeweler'

require './lib/subtitle_shifter'

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name        = "subtitle_shifter"
  gem.version     = SubtitleShifter::Version::STRING
  gem.homepage    = "http://github.com/gee-forr/subtitle_shifter"
  gem.license     = "MIT"
  gem.summary     = %Q{A simple library for adjusting SubRip (.srt) subtitles}
  gem.description = %Q{A simple little gem for modifying SubRip subtitle files. Done as a mentoring exercise with Citizen428, and taken from the Ruby Programming Challenge For Newbies}
  gem.email       = "gee.forr@gmail.com"
  gem.authors     = ["Gabriel Fortuna"]
  gem.executables = ['shift_subtitle']

  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  gem.add_development_dependency "minitest", ">= 0"
  gem.add_development_dependency "bundler", "~> 1.0.0"
  gem.add_development_dependency "jeweler", "~> 1.6.4"
  gem.add_development_dependency "rcov", ">= 0"
  gem.add_development_dependency "rdoc", ">= 0"
end

Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test' << 'spec'
  test.pattern = 'test/**/*_spec.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/*_spec.rb'
  test.verbose = true
  test.rcov_opts << '--exclude "gems/*"'
end

task :default => :test

#require 'rdoc/task'
#RDoc::Task.new do |rdoc|
  #version = File.exist?('VERSION') ? File.read('VERSION') : ""
#
  #rdoc.rdoc_dir = 'rdoc'
  #rdoc.title = "subtitle_shifter #{version}"
  #rdoc.rdoc_files.include('README*')
  #rdoc.rdoc_files.include('lib/**/*.rb')
#end
