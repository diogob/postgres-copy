# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)


Gem::Specification.new do |s|
  s.name                  = "postgres-copy"
  s.version               = "1.3.0"
  s.platform              = Gem::Platform::RUBY
  s.required_ruby_version = ">= 1.9.3"
  s.authors               = ["Diogo Biazus"]
  s.description           = "Now you can use the super fast COPY for import/export data directly from your AR models."
  s.email                 = "diogob@gmail.com"
  git_files               = `git ls-files`.split("\n") rescue ''
  s.files                 = git_files
  s.test_files            = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables           = []
  s.require_paths         = %w(lib)
  s.homepage              = "http://github.com/diogob/postgres-copy"
  s.require_paths         = ["lib"]
  s.summary               = "Put COPY command functionality in ActiveRecord's model class"

  s.add_dependency "pg", ">= 0.17"
  s.add_dependency "activerecord", '>= 5.1'
  s.add_dependency "responders"
  s.add_development_dependency "bundler"
  s.add_development_dependency "rdoc"
  s.add_development_dependency "rspec", "~> 2.12"
  s.add_development_dependency "rake", "~> 11.2.2"
end

