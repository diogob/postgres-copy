# activerecord-postgres-copy

This Gem will enable your AR models to use the PostgreSQL COPY command to import/export data in CSV format.
It's still in its ealry stages of development, *not production ready*.

## Install

    gem install activerecord-postgres-copy

## Usage

The gem will add two aditiontal class methods to ActiveRecord::Base as a monkey patch (I'll change this soon):

* pg_copy_to (description yet to be added)
* pg_copy_from (description yet to be added)


## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2011 Diogo Biazus. See LICENSE for details.
