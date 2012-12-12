# postgres-copy

This Gem will enable your AR models to use the PostgreSQL COPY command to import/export data in CSV format.
If you need to tranfer data between a PostgreSQL database and CSV files, the PostgreSQL native CSV parser
will give you a greater performance than using the ruby CSV+INSERT commands.
I have not found time to make accurate benchmarks, but in the use scenario where I have developed the gem
I have had a four-fold performance gain.
This gem was written having the Rails framework in mind, I think it could work only with active-record, 
but I will assume in this README that you are using Rails.

## Install

Put it in your Gemfile

    gem 'postgres-copy'

Run the bundle command

    bundle

## Usage

The gem will add two aditiontal class methods to ActiveRecord::Base:

* pg_copy_to 
* pg_copy_to_string
* pg_copy_from

### Using pg_copy_to and pg_copy_to_string

You can go to the rails console and try some cool things first.
The first and most basic use case, let's copy the enteire content of a database table to a CSV file on the database server disk.
Assuming we have a users table and a User AR model:

    User.pg_copy_to '/tmp/users.csv'

This will execute in the database the command:

    COPY (SELECT "users".* FROM "users" ) TO '/tmp/users.csv' WITH DELIMITER ',' CSV HEADER

Remark that the file will be created in the database server disk.  
But what if you want to write the lines in a file on the server that is running Rails, instead of the database?  
In this case you can pass a block and retrieve the generated lines and then write them to a file:

    File.open('/tmp/users.csv', 'w') do |f|
      User.pg_copy_to do |line|
        f.write line
      end
    end

Or, if you have enough memory, you can read all table contents to a string using .pg_copy_to_string

    puts User.pg_copy_to_string

Another insteresting feature of pg_copy_to is that it uses the scoped relation, it means that you can use ARel 
operations to generate different CSV files according to your needs.
Assuming we want to generate a file only with the names of users 1, 2 and 3:

    User.select("name").where(:id => [1,2,3]).pg_copy_to "/tmp/users.csv"

Which will generate the following SQL command:

    COPY (SELECT name FROM "users" WHERE "users"."id" IN (1, 2, 3)) TO '/tmp/users.csv' WITH DELIMITER ',' CSV HEADER

The COPY command also supports exporting the data in binary format.

    User.select("name").where(:id => [1,2,3]).pg_copy_to "/tmp/users.dat", :format => :binary

Which will generate the following SQL command:

    COPY (SELECT name FROM "users" WHERE "users"."id" IN (1, 2, 3)) TO '/tmp/users.dat' WITH BINARY

The copy_to_string method also supports this

    puts User.pg_copy_to_string(:format => :binary)



### Using pg_copy_from

Now, if you want to copy data from a CSV file into the database, you can use the pg_copy_from method.
It will allow you to copy data from an arbritary IO object or from a file in the database server (when you pass the path as string).
Let's first copy from a file in the database server, assuming again that we have a users table and
that we are in the Rails console:

    User.pg_copy_from "/tmp/users.csv"

This command will use the headers in the CSV file as fields of the target table, so beware to always have a header in the files you want to import.
If the column names in the CSV header do not match the field names of the target table, you can pass a map in the options parameter.

    User.pg_copy_from "/tmp/users.csv", :map => {'name' => 'first_name'}

In the above example the header name in the CSV file will be mapped to the field called first_name in the users table.
You can also manipulate and modify the values of the file being imported before they enter into the database using a block:

    User.pg_copy_from "/tmp/users.csv" do |row|
      row[0] = "fixed string"
    end

The above extample will always change the value of the first column to "fixed string" before storing it into the database.
For each iteration of the block row receives an array with the same order as the columns in the CSV file.


To copy a binary formatted data file or IO object you can specify the format as binary

    User.pg_copy_from "/tmp/users.dat", :format => :binary

NOTE: Columns must line up with the table unless you specify how they map to table columns.

To specify how the columns will map to the table you can specify the :columns option

    User.pg_copy_from "/tmp/users.dat", :format => :binary, :columns => [:id, :name]

Which will generate the following SQL command:

    COPY users (id, name) FROM '/tmp/users.dat' WITH BINARY


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
