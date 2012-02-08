require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "postgres-copy"
    gem.summary = %Q{Put COPY command functionality in ActiveRecord's model class}
    gem.description = %Q{Now you can use the super fast COPY for import/export data directly from your AR models.}
    gem.email = "diogob@gmail.com"
    gem.homepage = "http://github.com/diogob/postgres-copy"
    gem.authors = ["Diogo Biazus"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_dependency "activerecord", ">= 3.0.0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require "rspec/core/rake_task" # RSpec 2.0
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/*_spec.rb'
end
task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "postgres-copy #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
