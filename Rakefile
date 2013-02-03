# -*- encoding: utf-8 -*-
$:.unshift File.expand_path("../lib", __FILE__)
require 'bundler/gem_tasks'
require 'rubygems'
require 'rspec/core/rake_task'
require 'rdoc/task'

task :default => :spec

RSpec::Core::RakeTask.new(:spec)

Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "postgres-copy #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
